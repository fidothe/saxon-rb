require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents a Saxon XDM ExternalObject
    class ExternalObject
      include SequenceLike
      include ItemSequenceLike

      # @api private
      def initialize(s9_xdm_external_object)
        @s9_xdm_external_object = s9_xdm_external_object
      end

      # The underlying Saxon XdmExternalObject
      def to_java
        @s9_xdm_external_object
      end
    end
  end
end
