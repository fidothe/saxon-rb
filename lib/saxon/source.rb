require 'java'
require 'saxon/jaxp'
require 'uri'
require 'pathname'

module Saxon
  # Provides a wrapper around the JAXP StreamSource class Saxon uses to bring
  # the XML bytestream in. Provides some extra methods to make handling closing
  # the source and its inputstream after consumption more idiomatic
  class Source
    module Helpers
      # Given a File, or IO object which will return either #path or
      # #base_uri, return the #base_uri, if present, or the #path, if present, or
      # nil
      # @param [File, IO] io A File or IO
      #   object representing the input XML file or data, or a String containing
      #   the XML
      # @return [String, nil] the path or URI from the IO (or nil if there is none)
      def self.base_uri(io)
        if io.respond_to?(:base_uri)
          return io.base_uri.to_s
        end
        io.path if io.respond_to?(:path)
      end

      # Given a File or IO return a Java InputStream
      # @param [File, IO, org.jruby.util.IOInputStream, java.io.InputStream]
      #   io input to be converted to an input stream
      # @return [java.io.InputStream] the wrapped input
      def self.inputstream(io)
        case io
        when org.jruby.util.IOInputStream, java.io.InputStream
          io
        else
          io.to_inputstream if io.respond_to?(:read)
        end
      end

      # Given a path return a Java File object
      # @param [String, Pathname] path the path to the file
      # @return [java.io.File] the Java File object
      def self.file(path)
        java.io.File.new(path.to_s)
      end
    end

    PathChecker = ->(path) {
      File.file?(path)
    }
    URIChecker = ->(uri) {
      begin
        URI.parse(uri)
        true
      rescue URI::InvalidURIError
        false
      end
    }

    # Generate a Saxon::Source given an IO-like
    #
    # @param [IO, File] io The IO-like containing XML to be parsed
    # @param [Hash] opts
    # @option opts [String] :base_uri The Base URI for the Source - an
    #   absolute URI or relative path that will be used to resolve relative
    #   URLs in the XML. Setting this will override any path or URI derived
    #   from the IO-like.
    # @return [Saxon::Source] the Saxon::Source wrapping the input
    def self.from_io(io, opts = {})
      base_uri = opts.fetch(:base_uri) { Helpers.base_uri(io) }
      inputstream = Helpers.inputstream(io)
      stream_source = Saxon::JAXP::StreamSource.new(inputstream, base_uri)
      new(stream_source, inputstream)
    end

    # Generate a Saxon::Source given a path to a file
    #
    # @param [String, Pathname] path The path to the XML file to be parsed
    # @param [Hash] opts
    # @option opts [String] :base_uri The Base URI for the Source - an
    #   absolute URI or relative path that will be used to resolve relative
    #   URLs in the XML. Setting this will override the file path.
    # @return [Saxon::Source] the Saxon::Source wrapping the input
    def self.from_path(path, opts = {})
      stream_source = Saxon::JAXP::StreamSource.new(Helpers.file(path))
      stream_source.setSystemId(opts[:base_uri]) if opts[:base_uri]
      new(stream_source)
    end

    # Generate a Saxon::Source given a URI
    #
    # @param [String, URI] uri The URI to the XML file to be parsed
    # @param [Hash] opts
    # @option opts [String] :base_uri The Base URI for the Source - an
    #   absolute URI or relative path that will be used to resolve relative
    #   URLs in the XML. Setting this will override the given URI.
    # @return [Saxon::Source] the Saxon::Source wrapping the input
    def self.from_uri(uri, opts = {})
      stream_source = Saxon::JAXP::StreamSource.new(uri.to_s)
      stream_source.setSystemId(opts[:base_uri]) if opts[:base_uri]
      new(stream_source)
    end

    # Generate a Saxon::Source given a string containing XML
    #
    # @param [String] string The string containing XML to be parsed
    # @param [Hash] opts
    # @option opts [String] :base_uri The Base URI for the Source - an
    #   absolute URI or relative path that will be used to resolve relative
    #   URLs in the XML. This will be nil unless set.
    # @return [Saxon::Source] the Saxon::Source wrapping the input
    def self.from_string(string, opts = {})
      reader = java.io.StringReader.new(string)
      stream_source = Saxon::JAXP::StreamSource.new(reader)
      stream_source.setSystemId(opts[:base_uri]) if opts[:base_uri]
      new(stream_source, reader)
    end

    def self.create(io_path_uri_or_string, opts = {})
      case io_path_uri_or_string
      when IO, File, java.io.InputStream
        from_io(io_path_uri_or_string, opts)
      when Pathname, PathChecker
        from_path(io_path_uri_or_string, opts)
      when URIChecker
        from_uri(io_path_uri_or_string, opts)
      else
        from_string(io_path_uri_or_string, opts)
      end
    end

    attr_reader :stream_source, :inputstream
    private :stream_source, :inputstream

    # @api private
    # @param [java.xml.transform.stream.StreamSource] stream_source The Java JAXP StreamSource
    # @param [java.io.InputStream, java.io.StringReader] inputstream The Java InputStream or StringReader
    def initialize(stream_source, inputstream = nil)
      @stream_source = stream_source
      @inputstream = inputstream
      @closed = false
    end

    # @return [String] The base URI of the Source
    def base_uri
      stream_source.getSystemId
    end

    # @param [String, URI] uri The URI to use as the Source's Base URI
    # @return [String] The new base URI of the Source
    def base_uri=(uri)
      stream_source.setSystemId(uri.to_s)
      base_uri
    end

    # Close the Source and its associated InputStream or Reader, allowing those
    # resources to be freed.
    # @return [TrueClass] Returns true
    def close
      inputstream.close
      @closed = true
    end

    # @return [Boolean] Returns true if the source is closed, false otherwise
    def closed?
      @closed
    end

    # Yields itself and then closes itself. To be used by DocumentBuilders or
    # other consumers, making it easy to ensure the source is closed after it
    # has been consumed.
    #
    # @raise [Saxon::SourceClosedError] if the Source has already been closed
    # @yield [source] Yields self to the block
    def consume(&block)
      raise SourceClosedError if closed?
      block.call(self)
      close
    end

    # @return [java.xml.transform.stream.StreamSource] The underlying JAXP StreamSource
    def to_java
      @stream_source
    end
  end

  class SourceClosedError < Exception; end
end
