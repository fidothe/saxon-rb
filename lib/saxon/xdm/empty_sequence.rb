require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents the empty sequence in XDM
    class EmptySequence
      def self.create
        @instance ||= new
      end

      include SequenceLike

      def sequence_enum
        [].to_enum
      end

      def sequence_size
        0
      end

      def ==(other)
        other.class == self.class
      end

      alias_method :eql?, :==

      def hash
        [].hash
      end

      def to_java
        @s9_xdm_empty_sequence ||= Saxon::S9API::XdmEmptySequence.getInstance
      end
    end
  end
end