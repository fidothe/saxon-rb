require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents an XDM Array
    class Array
      # Create a new {XDM::Array} from a Ruby Array. The contents of the array
      # will be converted to {XDM::Value}s using {XDM.Value()}. An existing
      # {S9API::XdmArray} will simply be wrapped and returned.
      #
      # @return [XDM::Array] the new XDM Array
      def self.create(array)
        case array
        when S9API::XdmArray
          new(array)
        else
          new(S9API::XdmArray.new(array.map { |item|
            XDM.Value(item).to_java
          }))
        end
      end

      include SequenceLike
      include ItemSequenceLike
      include Enumerable

      attr_reader :s9_xdm_array
      private :s9_xdm_array

      # @api private
      def initialize(s9_xdm_array)
        @s9_xdm_array = s9_xdm_array
      end

      # Iterate over the Array, yielding each element.
      # @yieldparam value [XDM::Value] the current value from the Array
      def each(&block)
        cached_array.each(&block)
      end

      # Fetch element at index +i+ in the array.
      # @param i [Integer] the index of the element to retrieve.
      def [](i)
        cached_array[i]
      end

      # @return [Integer] the length of the array
      def length
        s9_xdm_array.arrayLength
      end

      alias_method :size, :length

      # compares two {XDM::AtomicValue}s using the underlying Saxon and XDM
      # comparision rules
      #
      # @param other [Saxon::XDM::AtomicValue]
      # @return [Boolean]
      def ==(other)
        return false unless other.is_a?(XDM::Array)
        return false if length != other.length
        cached_array == other.to_a
      end

      # Return a (frozen) Ruby {::Array} containing all the elements of the {XDM::Array}
      def to_a
        cached_array
      end

      alias_method :eql?, :==

      # Compute a hash-code for this {Array}.
      #
      # Two {XDM::Array}s with the same content will have the same hash code (and will compare using eql?).
      # @see Object#hash
      def hash
        @hash ||= cached_array.hash
      end

      # @return the underlying Java XdmArray
      def to_java
        s9_xdm_array
      end

      private

      def cached_array
        @cached_array ||= s9_xdm_array.asList.map { |s9_xdm_value| XDM.Value(s9_xdm_value) }.freeze
      end
    end
  end
end
