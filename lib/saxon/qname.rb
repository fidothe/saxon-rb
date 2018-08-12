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

    def to_java
      s9_qname
    end

    def inspect
      "<Saxon::QName @prefix=#{prefix} @uri=#{uri} @local_name=#{local_name}>"
    end
  end
end
