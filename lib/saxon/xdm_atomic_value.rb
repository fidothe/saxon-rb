require_relative 'qname'
require_relative 'item_type'

module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element
  # or one of the other node chunks in the XDM.
  class XdmAtomicValue
    # Error thrown when an attempt to create QName-holding XdmAtomicValue is
    # made using anything other than a {Saxon::QName} instance
    class CannotCreateQNameFromLiteral < StandardError
    end

    XS_QNAME = ItemType.get_type('xs:QName')

    class << self
      # Convert a single Ruby value into an XdmAtomicValue
      #
      # If no explicit {ItemType} is passed, the correct type is guessed based
      # on the class of the value. (e.g. <tt>xs:date</tt> for {Date}.)
      #
      # Values are converted based on Ruby idioms and operations, so an explicit
      # {ItemType} of <tt>xs:boolean</tt> will use truthyness to evaluate the
      # value. This means that the Ruby string <tt>'false'</tt> will produce an
      # <tt>xs:boolean</tt> whose value is <tt>true</tt>, because all strings
      # are truthy. If you need to pass lexical strings unchanged, use
      # {XdmAtomicValue.from_lexical_string}.
      #
      # @param value [Object] the value to convert
      #
      # @param item_type [Saxon::ItemType, String] the value's type, as either
      #   an {ItemType} or a name (<tt>xs:date</tt>)
      #
      # @return [Saxon::XdmAtomicValue]
      def create(value, item_type = nil)
        return create_implying_item_type(value) if item_type.nil?

        item_type = ItemType.get_type(item_type)

        if item_type == XS_QNAME
          if value_is_qname?(value)
            return new(Saxon::S9API::XdmAtomicValue.new(value.to_java))
          end
          raise CannotCreateQNameFromLiteral
        end

        value_lexical_string = item_type.lexical_string(value)
        new(new_s9_xdm_atomic_value(value_lexical_string, item_type))
      end

      # convert a lexical string representation of an XDM Atomic Value into an
      # XdmAtomicValue.
      #
      # Note that this skips all conversion and checking of the string before
      # handing it off to Saxon.
      #
      # @param value [String] the lexical string representation of the value
      # @param item_type [Saxon::ItemType, String] the value's type, as either
      #   an {ItemType} or a name (<tt>xs:date</tt>)
      # @return [Saxon::XdmAtomicValue]
      def from_lexical_string(value, item_type)
        item_type = ItemType.get_type(item_type)
        raise CannotCreateQNameFromLiteral if item_type == XS_QNAME
        new(new_s9_xdm_atomic_value(value.to_s, item_type))
      end

      private

      def new_s9_xdm_atomic_value(value, item_type)
        Saxon::S9API::XdmAtomicValue.new(value.to_java, item_type.to_java)
      end

      def create_implying_item_type(value)
        return new(Saxon::S9API::XdmAtomicValue.new(value.to_java)) if value_is_qname?(value)

        item_type = ItemType.get_type(value.class)

        new(new_s9_xdm_atomic_value(item_type.lexical_string(value), item_type))
      end

      def value_is_qname?(value)
        QName === value || S9API::QName === value
      end
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

    # @return [Saxon::S9API::XdmAtomicValue] The underlying Saxon Java XDM
    # atomic value object.
    def to_java
      s9_xdm_atomic_value
    end

    # Return the value as a String. Like calling XPath's <tt>string()</tt>
    # function.
    #
    # @return [String] The string representation of the value
    def to_s
      s9_xdm_atomic_value.toString
    end

    # @return [Saxon::ItemType] The ItemType of the value
    def item_type
      @item_type ||= Saxon::ItemType.get_type(Saxon::QName.resolve(s9_xdm_atomic_value.getTypeName))
    end

    # Return the value as an instance of the Ruby class that best represents the
    # type of the value. Types with no sensible equivalent are returned as their
    # lexical string form
    #
    # @return [Object] A Ruby object representation of the value
    def to_ruby
      @ruby_value ||= item_type.ruby_value(self).freeze
    end

    # compares two {XdmAtomicValue}s using the underlying Saxon and XDM
    # comparision rules
    #
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
