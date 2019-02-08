require_relative 'qname'

module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element or one of the other node chunks in the XDM.
  class XdmAtomicValue
    # convert a single Ruby value into an XdmAtomicValue
    #
    # @param value the value to convert
    # @return [Saxon::XdmAtomicValue]
    def self.create(value)
      new(Saxon::S9API::XdmAtomicValue.new(value))
    end

    attr_reader :s9_xdm_atomic_value
    private :s9_xdm_atomic_value

    # @api private
    def initialize(s9_xdm_atomic_value)
      @s9_xdm_atomic_value = s9_xdm_atomic_value
    end

    # Return a {QName} representing the type of the value
    #
    # @return [Saxon::QName] the {QName} of the value's type
    def type_name
      @type_name ||= Saxon::QName.new(s9_xdm_atomic_value.getTypeName)
    end

    # @return [Saxon::S9API::XdmAtomicValue] The underlying Saxon Java XDM atomic value object.
    def to_java
      s9_xdm_atomic_value
    end

    # compares two {XdmAtomicValue}s using the underlying Saxon and XDM comparision rules
    # @param other [Saxon::XdmAtomicValue]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(XdmAtomicValue)
      s9_xdm_atomic_value.equals(other.to_java)
    end

    alias_method :eql?, :==

    def hash
      @hash ||= s9_xdm_atomic_value.hashCode
    end
  end
end
