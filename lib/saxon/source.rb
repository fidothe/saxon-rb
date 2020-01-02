require 'java'
require 'saxon/jaxp'
require 'uri'
require 'open-uri'
require 'pathname'

module Saxon
  # Provides a wrapper around the JAXP StreamSource class Saxon uses to bring
  # the XML bytestream in. Provides some extra methods to make handling closing
  # the source and its inputstream after consumption more idiomatic
  class Source
    # Helper methods for getting Java-useful representations of source document
    # strings and files
    module Helpers
      # Given a File, or IO object which will return either #path or
      # #base_uri, return the #base_uri, if present, or the #path, if present, or
      # nil
      #
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

      # Given a File or IO return a Java InputStream, or an InputStreamReader if
      # the Encoding is explicitly specified (rather than inferred from the
      # <?xml charset="..."?>) declaration in the source.
      #
      # @param io [File, IO, org.jruby.util.IOInputStream, java.io.InputStream]
      #   input to be converted to an input stream
      # @param encoding [Encoding, String] the character encoding to be used to
      #   for the stream, overriding the XML parser.
      # @return [java.io.InputStream] the wrapped input
      def self.inputstream(io, encoding = nil)
        stream = case io
        when org.jruby.util.IOInputStream, java.io.InputStream
          io
        else
          io.to_inputstream if io.respond_to?(:read)
        end

        return stream if encoding.nil?
        java.io.InputStreamReader.new(stream, ruby_encoding_to_charset(encoding))
      end

      # Given a path return a Java File object
      #
      # @param path [String, Pathname] the path to the file
      # @return [java.io.File] the Java File object
      def self.file(path)
        java.io.File.new(path.to_s)
      end

      # Given a file path and encoding, return a Java InputStreamReader object
      # for the file.
      #
      # @param path [String, Pathname] the path to the file
      # @param encoding [String, Encoding] the file's character encoding
      # @return [java.io.InputStreamReader] a Java InputStreamReader object
      #   wrapping a FileInputStream for the file
      def self.file_reader(path, encoding)
        java.io.InputStreamReader.new(java.io.FileInputStream.new(file(path)), ruby_encoding_to_charset(encoding))
      end

      # Return a File or Reader object for a file, depending on whether the
      # encoding must be explicitly specified or not.
      #
      # @param path [String, Pathname] the path to the file
      # @param encoding [String, Encoding] the file's character encoding
      # @return [java.io.Reader] a Java Reader object
      def self.file_or_reader(path, encoding = nil)
        encoding.nil? ? file(path) : file_reader(path, encoding)
      end

      # Return a Reader object for the String with an explicitly set encoding.
      # If the encoding is +ASCII_8BIT+ then a binary-mode StreamReader is
      # returned, rather than a character Reader
      #
      # @param string [String] the string
      # @param encoding [String, Encoding] the string's character encoding
      # @return [java.io.InputStream, java.io.Reader] a Java InputStream or Reader object
      def self.string_reader(string, encoding)
        inputstream = StringIO.new(string).to_inputstream
        encoding = ruby_encoding(encoding)
        return inputstream if encoding == ::Encoding::ASCII_8BIT
        java.io.InputStreamReader.new(inputstream, ruby_encoding_to_charset(encoding))
      end

      # Figure out the equivalent Java +Charset+ for a Ruby {Encoding}.
      #
      # @param encoding [String, Encoding] the encoding to find a +Charset+ for
      def self.ruby_encoding_to_charset(encoding)
        ruby_encoding(encoding).to_java.getEncoding.getCharset
      end

      # Given a String with an {Encoding} name or an {Encoding} instance, return
      # an {Encoding} instance
      #
      # @param encoding [String, Encoding] the encoding or encoding name
      # @return [Encoding] the encoding
      def self.ruby_encoding(encoding)
        encoding.nil? ? nil : ::Encoding.find(encoding)
      end
    end

    # Lambda that checks if the given path exists and is a file
    PathChecker = ->(path) {
      File.file?(path)
    }
    # Lambda that checks if the given string is a valid URI
    URIChecker = ->(uri) {
      begin
        URI.parse(uri)
        true
      rescue URI::InvalidURIError
        false
      end
    }

    class << self
      # Generate a Saxon::Source given an IO-like
      #
      # @param [IO, File] io The IO-like containing XML to be parsed
      # @param [Hash] opts
      # @option opts [String] :base_uri The Base URI for the Source - an
      #   absolute URI or relative path that will be used to resolve relative
      #   URLs in the XML. Setting this will override any path or URI derived
      #   from the IO-like.
      # @option opts [String, Encoding] :encoding The encoding of the source.
      #   Note that specifying this will force the parser to ignore the charset
      #   if it's set in the XML declaration of the source. Only really useful
      #   if there's a discrepancy between the source's declared and actual
      #   encoding. Defaults to the <?xml charset="..."?> declaration in the
      #   source.
      # @return [Saxon::Source] the Saxon::Source wrapping the input
      def from_io(io, opts = {})
        base_uri = opts.fetch(:base_uri) { Helpers.base_uri(io) }
        encoding = opts.fetch(:encoding, nil)
        inputstream = Helpers.inputstream(io, encoding)
        from_inputstream_or_reader(inputstream, base_uri)
      end

      # Generate a Saxon::Source given a path to a file
      #
      # @param [String, Pathname] path The path to the XML file to be parsed
      # @param [Hash] opts
      # @option opts [String] :base_uri The Base URI for the Source - an
      #   absolute URI or relative path that will be used to resolve relative
      #   URLs in the XML. Setting this will override the file path.
      # @option opts [String, Encoding] :encoding The encoding of the source.
      #   Note that specifying this will force the parser to ignore the charset
      #   if it's set in the XML declaration of the source. Only really useful
      #   if there's a discrepancy between the source's declared and actual
      #   encoding. Defaults to the <?xml charset="..."?> declaration in the
      #   source.
      # @return [Saxon::Source] the Saxon::Source wrapping the input
      def from_path(path, opts = {})
        encoding = opts.fetch(:encoding, nil)
        return from_inputstream_or_reader(Helpers.file(path), opts[:base_uri]) if encoding.nil?
        reader = Helpers.file_reader(path, encoding)
        base_uri = opts.fetch(:base_uri) { File.expand_path(path) }
        from_inputstream_or_reader(reader, base_uri)
      end

      # Generate a Saxon::Source given a URI
      #
      # @param [String, URI] uri The URI to the XML file to be parsed
      # @param [Hash] opts
      # @option opts [String] :base_uri The Base URI for the Source - an
      #   absolute URI or relative path that will be used to resolve relative
      #   URLs in the XML. Setting this will override the given URI.
      # @option opts [String, Encoding] :encoding The encoding of the source.
      #   Note that specifying this will force the parser to ignore the charset
      #   if it's set in the XML declaration of the source. Only really useful
      #   if there's a discrepancy between the source's declared and actual
      #   encoding. Defaults to the <?xml charset="..."?> declaration in the
      #   source.
      # @return [Saxon::Source] the Saxon::Source wrapping the input
      def from_uri(uri, opts = {})
        encoding = opts.fetch(:encoding, nil)
        return from_io(open(uri), encoding: encoding) if encoding
        from_inputstream_or_reader(uri.to_s, opts[:base_uri])
      end

      # Generate a Saxon::Source given a string containing XML
      #
      # @param [String] string The string containing XML to be parsed
      # @param [Hash] opts
      # @option opts [String] :base_uri The Base URI for the Source - an
      #   absolute URI or relative path that will be used to resolve relative
      #   URLs in the XML. This will be nil unless set.
      # @option opts [String, Encoding] :encoding The encoding of the source.
      #   Note that specifying this will force the parser to ignore the charset
      #   if it's set in the XML declaration of the source. Only really useful
      #   if there's a discrepancy between the encoding of the string and the
      #   encoding of the source. Defaults to the encoding of the string, unless
      #   that is ASCII-8BIT, in which case the parser will use the
      #   <?xml charset="..."?> declaration in the source to pick the encoding.
      # @return [Saxon::Source] the Saxon::Source wrapping the input
      def from_string(string, opts = {})
        encoding = opts.fetch(:encoding) { string.encoding }
        reader = Helpers.string_reader(string, encoding)
        from_inputstream_or_reader(reader, opts[:base_uri])
      end

      # Generate a Saxon::Source from one of the several inputs allowed.
      #
      # If possible the character encoding of the input source will be left to
      # the XML parser to discover (from the <tt><?xml charset="..."?></tt> XML
      # declaration).
      #
      # The Base URI for the source (its absolute path, or URI) can be set by
      # passing in the +:base_uri+ option. This is the same thing as an XML
      # document's 'System ID' - Base URI is the term most widely used in Ruby
      # libraries for this, so that's what's used here.
      #
      # If the source's character encoding can't be correctly discovered by the
      # parser from the XML declaration (<tt><?xml version="..."
      # charset="..."?></tt> at the top of the document), then it can be passed
      # as the +:encoding+ option.
      #
      # If an existing {Source} is passed in, simply return it.
      #
      # @param [Saxon::Source, IO, File, String, Pathname, URI] input The XML to be parsed
      # @param [Hash] opts
      # @option opts [String] :base_uri The Base URI for the Source - an
      #   absolute URI or relative path that will be used to resolve relative
      #   URLs in the XML. Setting this will override any path or URI derived
      #   from an IO, URI, or Path.
      # @option opts [String, Encoding] :encoding The encoding of the source.
      #   Note that specifying this will force the parser to ignore the charset
      #   if it's set in the XML declaration of the source. Only really useful
      #   if there's a discrepancy between the source's declared and actual
      #   encoding. Defaults to the <?xml charset="..."?> declaration in the
      #   source.
      # @return [Saxon::Source] the Saxon::Source wrapping the input
      def create(input, opts = {})
        case input
        when Saxon::Source
          input
        when IO, File, java.io.InputStream, StringIO
          from_io(input, opts)
        when Pathname, PathChecker
          from_path(input, opts)
        when URIChecker
          from_uri(input, opts)
        else
          from_string(input, opts)
        end
      end

      private

      def from_inputstream_or_reader(inputstream_or_reader, base_uri = nil)
        stream_source = Saxon::JAXP::StreamSource.new(inputstream_or_reader)
        stream_source.setSystemId(base_uri) if base_uri
        new(stream_source, inputstream_or_reader)
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

  # Error raised when trying to consume an already-consumed, and closed, Source
  class SourceClosedError < Exception; end
end
