require_relative 'qname'
require_relative 'item_type'

module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element or one of the other node chunks in the XDM.
  class XdmAtomicValue
    # convert a single Ruby value into an XdmAtomicValue
    #
    # @param value the value to convert
    # @return [Saxon::XdmAtomicValue]
    def self.create(value, item_type = nil)
      item_type_lookup = item_type || value.class
      item_type = ItemType.get_type(item_type_lookup)

      value_lexical_string = item_type.lexical_string(value)
      new(Saxon::S9API::XdmAtomicValue.new(value_lexical_string.to_java, item_type.to_java))
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

    # @return [Saxon::ItemType] The ItemType of the value
    def item_type
      @item_type ||= Saxon::ItemType.get_type(Saxon::QName.resolve(s9_xdm_atomic_value.getTypeName))
    end

    # Return the value as an instance of the Ruby class that best represents
    # the type of the value. Types with no sensible equivalent are returned
    # as their lexical string form
    #
    # @return [Object] A Ruby object representation of the value
    def to_ruby
      @ruby_value ||= item_type.ruby_value(self).freeze
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
