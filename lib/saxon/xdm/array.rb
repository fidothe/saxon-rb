require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents an XDM Array
    class Array
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

      def each(&block)
        cached_array.each(&block)
      end

      def [](i)
        cached_array[i]
      end

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

      alias_method :eql?, :==

      def hash
        @hash ||= cached_array.hash
      end

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
