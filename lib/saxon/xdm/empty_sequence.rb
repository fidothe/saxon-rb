require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents the empty sequence in XDM
    class EmptySequence
      # Returns an instance. Effectively a Singleton because the EmptySequence
      # is immutable, and empty. An instance is completely interchangeable with
      # another. The instance is cached, but multiple instances may exist across
      # threads. We don't prevent that because it's immaterial.
      # @return [EmptySequence] The empty sequence
      def self.create
        @instance ||= new
      end

      include SequenceLike

      # @return [Enumerator] an enumerator over an empty Array
      def sequence_enum
        [].to_enum
      end

      # @return [Integer] the size of the sequence (always 0)
      def sequence_size
        0
      end

      # All instances of {EmptySequence} are equal to each other.
      #
      # @param other [Object] the object to compare self against
      # @return [Boolean] Whether this object is equal to the other
      def ==(other)
        other.class == self.class
      end

      alias_method :eql?, :==

      # @return [Integer] the hash code. All instances have the same hash code.
      def hash
        [].hash
      end

      # @return [net.sf.saxon.s9api.XDMEmptySequence] the underlying Java empty sequence
      def to_java
        @s9_xdm_empty_sequence ||= Saxon::S9API::XdmEmptySequence.getInstance
      end
    end
  end
end