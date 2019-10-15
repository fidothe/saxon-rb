require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # An XPath Data Model Value object, representing a Sequence.
    class Value
      include XDM::SequenceLike
      include Enumerable

      class << self
        # Create a new XDM::Value sequence containing the items passed in as a Ruby enumerable.
        #
        # @param items [Enumerable] A list of members
        # @return [Saxon::XDM::Value] The XDM value
        def create(*items)
          items = items.flatten
          case items.size
          when 0
            XDM.EmptySequence()
          when 1
            if existing_value = maybe_xdm_value(items.first)
              return existing_value
            end
            XDM.Item(items.first)
          else
            new(Saxon::S9API::XdmValue.new(wrap_items(items)))
          end
        end

        private

        def maybe_xdm_value(item)
          return item if item.is_a?(self)
          return new(item) if item.instance_of?(Saxon::S9API::XdmValue)
          false
        end

        def wrap_items(items)
          result = []
          items.map { |item|
            wrap_item(item, result)
          }
          result
        end

        def wrap_item(item, result)
          if item.respond_to?(:sequence_enum)
            item.sequence_enum.each do |item|
              result << item.to_java
            end
          elsif item.respond_to?(:each)
            item.each do |item|
              result << XDM.Item(item).to_java
            end
          else
            result << XDM.Item(item).to_java
          end
        end
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
      #   @yieldparam item [Saxon::XDM::AtomicValue, Saxon::XDM::Node] the item.
      def each(&block)
        to_enum.each(&block)
      end

      # @return [Saxon::S9API::XdmValue] The underlying Saxon Java XDM valuee object.
      def to_java
        @s9_xdm_value
      end

      # Compare this XDM::Value with another. Currently this requires iterating
      # across the sequence, and the other sequence and comparing each member
      # with the corresponding member in the other sequence.
      #
      # @param other [Saxon::XDM::Value] The XDM::Value to be compare against
      # @return [Boolean] whether the two XDM::Values are equal
      def ==(other)
        return false unless other.is_a?(XDM::Value)
        return false unless other.size == size
        not_okay = to_enum.zip(other.to_enum).find { |mine, theirs|
          mine != theirs
        }
        not_okay.nil? || !not_okay
      end

      alias_method :eql?, :==

      # The hash code for the XDM::Value
      # @return [Fixnum] The hash code
      def hash
        @hash ||= to_a.hash
      end

      # Returns a lazy Enumerator over the sequence
      # @return [Enumerator::Lazy] the enumerator
      def to_enum
        s9_xdm_value.to_enum.lazy.map { |s9_xdm_item|
          XDM.Item(s9_xdm_item)
        }.each
      end

      alias_method :enum_for, :to_enum

      def sequence_enum
        to_enum
      end

      def sequence_size
        s9_xdm_value.size
      end
    end

    # Placeholder class for Saxon Items that we haven't gotten to yet
    class XDM::UnhandledItem
      def initialize(s9_xdm_item)
        @s9_xdm_item = s9_xdm_item
      end

      def to_java
        @s9_xdm_item
      end
    end
  end
end