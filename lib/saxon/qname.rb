require 'saxon/s9api'

module Saxon
  # Represents QNames
  class QName
    # Create a {QName} from a Clark-notation string.
    #
    # Clark-notation for QNames uses +{}+ to delimit the namespace, so for a
    # QName not in a namespace it's simply +local-name+, and for one in a
    # namespace it's +{http://example.org/ns}local-name+
    #
    # @param clark_string [String] A QName in Clark notation.
    # @return [Saxon::QName] A QName
    def self.clark(clark_string)
      s9_qname = Saxon::S9API::QName.fromClarkName(clark_string)
      new(s9_qname)
    end

    # Create a {QName} from an Expanded QName string.
    #
    # Expanded QNames uses +Q{}+ to delimit the namespace, so for a
    # QName not in a namespace it's simply +Q{}local-name+ (or +local-name}), and for one in a
    # namespace it's +Q{http://example.org/ns}local-name+
    #
    # @param eqname_string [String] A QName in Expanded QName notation.
    # @return [Saxon::QName] A QName
    def self.eqname(eqname_string)
      s9_qname = Saxon::S9API::QName.fromEQName(eqname_string)
      new(s9_qname)
    end

    # Create a {QName} from prefix, uri, and local name options
    #
    # @param opts [Hash]
    # @option [String] :prefix the namespace prefix to use (optional, requires +:uri+ passed too)
    # @option [String] :uri the namespace URI to use (only required for QNames in a namespace)
    # @option [String] :local_name the local-part of the QName. Required.
    # @return [Saxon::QName] the QName
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
    # If the arg is a string, it's resolved by using {resolve_qname_string}
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

    # Resolve a QName string of the form +"prefix:local-name"+ into a
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

    # Compare this QName with another. They compare equal if they have same URI
    # and local name. Prefix is ignored.
    #
    # @param other [Saxon::QName] the QName to compare against
    # @return [Boolean] whether the two compare equal
    def ==(other)
      return false unless other.is_a?(QName)
      s9_qname.equals(other.to_java)
    end
    alias_method :eql?, :==

    # Compute a hash-code for this {QName}.
    #
    # Two {QNames}s with the same local name and URI will have the same hash code (and will compare using eql?).
    # @see Object#hash
    def hash
      @hash ||= (local_name + uri).hash
    end

    # @return [Saxon::S9API::QName] the underlying Saxon QName object
    def to_java
      s9_qname
    end

    # convert the QName to a lexical string, using the prefix (if there is one).
    # So, <tt>Saxon::QName.clark('{http://example.org/#ns}hello').to_s</tt>
    # returns <tt>'hello'</tt>, and <tt>Saxon::QName.create(prefix: 'pre', uri:
    # 'http://example.org/#ns', local_name: 'hello').to_s</tt> returns
    # <tt>'pre:hello'</tt>
    def to_s
      s9_qname.to_s
    end

    # Returns a more detailed string representation of the object, showing
    # prefix, uri, and local_name instance variables
    def inspect
      "<Saxon::QName @prefix=#{prefix} @uri=#{uri} @local_name=#{local_name}>"
    end

    # Raised when an attempt is made to resolve a <tt>prefix:local-name</tt>
    # into a QName, and the prefix has not been bound to a namespace URI.
    class PrefixedStringWithoutNSURIError < RuntimeError
      def initialize(qname_string, prefix)
        @qname_string, @prefix = qname_string, prefix
      end

      # The error message reports the unbound prefix and complete QName
      def to_s
        "Namespace prefix ‘#{@prefix}’ for QName ‘#{@qname_string}’ is not bound to a URI"
      end
    end
  end
end
