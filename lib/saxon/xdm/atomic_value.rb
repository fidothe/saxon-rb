require_relative '../qname'
require_relative '../item_type'

module Saxon
  module XDM
  # An XPath Data Model Node object, representing an XML document, or an element
  # or one of the other node chunks in the XDM.
  class AtomicValue
    # Error thrown when an attempt to create QName-holding XDM::AtomicValue is
    # made using anything other than a {Saxon::QName} or s9api.QName instance.
    #
    # QNames are dependent on the namespace URI, which isn't present in the
    # lexical string you normally see (e.g. <tt>prefix:name</tt>). Prefixes are
    # only bound to a URI in the context of a particular document, so creating
    # them imlpicitly through the XDM::AtomicValue creation process doesn't really
    # work. They need to be created explicitly and then handed in to be wrapped.
    class CannotCreateQNameFromString < StandardError
      def to_s
        "QName XDM::AtomicValues must be created using an instance of Saxon::QName, not a string like 'prefix:name': Prefix URI binding is undefined at this point"
      end
    end

    # xs:NOTATION is another QName-holding XDM type. Unlike xs:QName, there
    # isn't a way to create these outside of parsing an XML document within
    # Saxon, so attempting to do so raises this error.
    class NotationCannotBeDirectlyCreated < StandardError
      def to_s
        "xs:NOTATION XDM::AtomicValues cannot be directly created outside of XML parsing."
      end
    end

    XS_QNAME = ItemType.get_type('xs:QName')
    XS_NOTATION = ItemType.get_type('xs:NOTATION')

    class << self
      # Convert a single Ruby value into an XDM::AtomicValue
      #
      # If no explicit {ItemType} is passed, the correct type is guessed based
      # on the class of the value. (e.g. <tt>xs:date</tt> for {Date}.)
      #
      # Values are converted based on Ruby idioms and operations, so an explicit
      # {ItemType} of <tt>xs:boolean</tt> will use truthyness to evaluate the
      # value. This means that the Ruby string <tt>'false'</tt> will produce an
      # <tt>xs:boolean</tt> whose value is <tt>true</tt>, because all strings
      # are truthy. If you need to pass lexical strings unchanged, use
      # {XDM::AtomicValue.from_lexical_string}.
      #
      # @param value [Object] the value to convert
      #
      # @param item_type [Saxon::ItemType, String] the value's type, as either
      #   an {ItemType} or a name (<tt>xs:date</tt>)
      #
      # @return [Saxon::XDM::AtomicValue]
      def create(value, item_type = nil)
        return create_implying_item_type(value) if item_type.nil?

        item_type = ItemType.get_type(item_type)

        return new(Saxon::S9API::XdmAtomicValue.new(value.to_java)) if item_type == XS_QNAME && value_is_qname?(value)
        raise NotationCannotBeDirectlyCreated if item_type == XS_NOTATION

        value_lexical_string = item_type.lexical_string(value)
        new(new_s9_xdm_atomic_value(value_lexical_string, item_type))
      end

      # convert a lexical string representation of an XDM Atomic Value into an
      # XDM::AtomicValue.
      #
      # Note that this skips all conversion and checking of the string before
      # handing it off to Saxon.
      #
      # @param value [String] the lexical string representation of the value
      # @param item_type [Saxon::ItemType, String] the value's type, as either
      #   an {ItemType} or a name (<tt>xs:date</tt>)
      # @return [Saxon::XDM::AtomicValue]
      def from_lexical_string(value, item_type)
        item_type = ItemType.get_type(item_type)
        raise CannotCreateQNameFromString if item_type == XS_QNAME
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

    # compares two {XDM::AtomicValue}s using the underlying Saxon and XDM
    # comparision rules
    #
    # @param other [Saxon::XDM::AtomicValue]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(XDM::AtomicValue)
      s9_xdm_atomic_value.equals(other.to_java)
    end

    alias_method :eql?, :==

    def hash
      @hash ||= s9_xdm_atomic_value.hashCode
    end
  end
end
end