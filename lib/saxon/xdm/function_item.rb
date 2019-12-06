require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents an XDM Function Item
    class FunctionItem
      include SequenceLike
      include ItemSequenceLike

      # @api private
      def initialize(s9_xdm_function_item)
        @s9_xdm_function_item = s9_xdm_function_item
      end

      # The underlying Saxon XdmFunctionItem
      def to_java
        @s9_xdm_function_item
      end
    end
  end
end
