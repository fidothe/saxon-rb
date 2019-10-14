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

      # @api private
      def initialize(s9_xdm_array)
        @s9_xdm_array = s9_xdm_array
      end

      def each(&block)
        @s9_xdm_array.asList.map { |s9_xdm_value| XDM.Value(s9_xdm_value) }.each(&block)
      end

      def to_java
        @s9_xdm_array
      end
    end
  end
end
