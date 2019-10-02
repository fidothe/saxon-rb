require_relative 'xdm_node'
require_relative 'xdm_atomic_value'

module Saxon
  # An XPath Data Model Value object, representing a Sequence.
  class XdmValue
    include Enumerable

    def self.wrap_s9_xdm_value(s9_xdm_value)
      return new(s9_xdm_value) if s9_xdm_value.instance_of?(Saxon::S9API::XdmValue)
      case s9_xdm_value
      when Saxon::S9API::XdmEmptySequence
        new([])
      else
        wrap_s9_xdm_item(s9_xdm_value)
      end
    end

    def self.wrap_s9_xdm_item(s9_xdm_item)
      if s9_xdm_item.isAtomicValue
        XdmAtomicValue.new(s9_xdm_item)
      else
        case s9_xdm_item
        when Saxon::S9API::XdmNode
          XdmNode.new(s9_xdm_item)
        else
          XdmUnhandledItem.new(s9_xdm_item)
        end
      end
    end

    # Create a new XdmValue sequence containing the items passed in as a Ruby enumerable.
    #
    # @param items [Enumerable] A list of XDM Item members
    # @return [Saxon::XdmValue] The XDM value
    def self.create(items)
      new(Saxon::S9API::XdmValue.makeSequence(items.map(&:to_java)))
    end

    attr_reader :s9_xdm_value
    private :s9_xdm_value

    # @api private
    def initialize(s9_xdm_value)
      @s9_xdm_value = s9_xdm_value
    end

    # @return [Fixnum] The size of the sequence
    def size
      s9_xdm_value.size
    end

    # Calls the given block once for each Item in the sequence, passing that
    # item as a parameter. Returns the value itself.
    #
    # If no block is given, an Enumerator is returned.
    #
    # @overload
    #   @yield [item] The current XDM Item
    #   @yieldparam item [Saxon::XdmAtomicValue, Saxon::XdmNode] the item.
    def each(&block)
      to_enum.each(&block)
    end

    # @return [Saxon::S9API::XdmValue] The underlying Saxon Java XDM valuee object.
    def to_java
      @s9_xdm_value
    end

    # Compare this XdmValue with another. Currently this requires iterating
    # across the sequence, and the other sequence and comparing each member
    # with the corresponding member in the other sequence.
    #
    # @param other [Saxon::XdmValue] The XdmValue to be compare against
    # @return [Boolean] whether the two XdmValues are equal
    def ==(other)
      return false unless other.is_a?(XdmValue)
      return false unless other.size == size
      not_okay = to_enum.zip(other.to_enum).find { |mine, theirs|
        mine != theirs
      }
      not_okay.nil? || !not_okay
    end

    alias_method :eql?, :==

    # The hash code for the XdmValue
    # @return [Fixnum] The hash code
    def hash
      @hash ||= to_a.hash
    end

    # Returns a lazy Enumerator over the sequence
    # @return [Enumerator::Lazy] the enumerator
    def to_enum
      s9_xdm_value.each.lazy.map { |s9_xdm_item|
        self.class.wrap_s9_xdm_item(s9_xdm_item)
      }.each
    end

    alias_method :enum_for, :to_enum
  end

  # Placeholder class for Saxon Items that we haven't gotten to yet
  class XdmUnhandledItem
    def initialize(s9_xdm_item)
      @s9_xdm_item = s9_xdm_item
    end

    def to_java
      @s9_xdm_item
    end
  end
end
