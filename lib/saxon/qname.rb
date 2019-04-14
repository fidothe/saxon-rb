require 'saxon/s9api'

module Saxon
  # Represents QNames
  class QName
    def self.clark(clark_string)
      s9_qname = Saxon::S9API::QName.fromClarkName(clark_string)
      new(s9_qname)
    end

    def self.eqname(eqname_string)
      s9_qname = Saxon::S9API::QName.fromEQName(eqname_string)
      new(s9_qname)
    end

    def self.create(opts = {})
      prefix = opts[:prefix]
      uri = opts[:uri]
      begin
        local_name = opts.fetch(:local_name)
      rescue KeyError
        raise ArgumentError, "The :local_name option must be passed"
      end

      s9_qname = Saxon::S9API::QName.new(*[prefix, uri, local_name].compact)
      new(s9_qname)
    end

    # Resolve a QName string into a {Saxon::QName}.
    #
    # If the arg is a {Saxon::QName} already, it just gets returned. If
    # it's an instance of the underlying Saxon Java QName, it'll be wrapped
    # into a {Saxon::QName}
    #
    # If the arg is a string, it's resolved by using {resolve_variable_name}
    #
    # @param qname_or_string [String, Symbol, Saxon::QName] the qname to resolve
    # @param namespaces [Hash<String => String>] the set of namespaces as a hash of <tt>"prefix" => "namespace-uri"</tt>
    # @return [Saxon::QName]
    def self.resolve(qname_or_string, namespaces = {})
      case qname_or_string
      when String, Symbol
        resolve_qname_string(qname_or_string, namespaces)
      when self
        qname_or_string
      when Saxon::S9API::QName
        new(qname_or_string)
      end
    end

    # Resolve a QName string of the form <tt>"prefix:local-name"</tt> into a
    # {Saxon::QName} by looking up the namespace URI in a hash of
    # <tt>"prefix" => "namespace-uri"</tt>
    #
    # @param qname_string [String, Symbol] the QName as a <tt>"prefix:local-name"</tt> string
    # @param namespaces [Hash<String => String>] the set of namespaces as a hash of <tt>"prefix" => "namespace-uri"</tt>
    # @return [Saxon::QName]
    def self.resolve_qname_string(qname_string, namespaces = {})
      local_name, prefix = qname_string.to_s.split(':').reverse
      uri = nil

      if prefix
        uri = namespaces[prefix]
        raise self::PrefixedStringWithoutNSURIError.new(qname_string, prefix) if uri.nil?
      end

      create(prefix: prefix, uri: uri, local_name: local_name)
    end

    attr_reader :s9_qname
    private :s9_qname

    # @api private
    def initialize(s9_qname)
      @s9_qname = s9_qname
    end

    # @return [String] The local name part of the QName
    def local_name
      @s9_qname.getLocalName
    end

    # @return [String] The prefix part of the QName ('' if unset)
    def prefix
      @s9_qname.getPrefix
    end

    # @return [String] The namespace URI part of the QName ('' if unset)
    def uri
      @s9_qname.getNamespaceURI
    end

    # Return a Clark notation representation of the QName:
    #
    #    "{http://ns.url}local-name"
    #
    # Note that the prefix is lost in Clark notation.
    # @return [String] The QName represented using Clark notation.
    def clark
      @s9_qname.getClarkName
    end

    # Return a Extended QName notation representation of the QName:
    #
    #    "Q{http://ns.url}local-name"
    #
    # Note that the prefix is lost in EQName notation.
    # @return [String] The QName represented using EQName notation.
    def eqname
      @s9_qname.getEQName
    end

    def ==(other)
      return false unless other.is_a?(QName)
      s9_qname.equals(other.to_java)
    end
    alias_method :eql?, :==

    def hash
      @hash ||= (local_name + uri).hash
    end

    def to_java
      s9_qname
    end

    def to_s
      s9_qname.to_s
    end

    def inspect
      "<Saxon::QName @prefix=#{prefix} @uri=#{uri} @local_name=#{local_name}>"
    end

    class PrefixedStringWithoutNSURIError < RuntimeError
      def initialize(qname_string, prefix)
        @qname_string, @prefix = qname_string, prefix
      end

      def to_s
        "Namespace prefix ‘#{@prefix}’ for QName ‘#{@qname_string}’ is not bound to a URI"
      end
    end
  end
end
