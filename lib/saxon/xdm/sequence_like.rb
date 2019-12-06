module Saxon
  module XDM
    # Mixin for objects that are XDM Sequence-like in behaviour
    module SequenceLike
      # Implementors should return an {Enumerator} over the Sequence. For
      # {XDM::Value}s, this will just be the items in the sequence. For
      # XDM::AtomicValue or XDM::Node, this will be a single-item Enumerator so
      # that Items can be correctly treated as single-item Values.
      def sequence_enum
        raise NotImplementedError
      end

      # Implementors should return the size of the Sequence. For
      # {XDM::AtomicValue} this will always be 1.
      # @return [Integer] the sequence size
      def sequence_size
        raise NotImplementedError
      end

      # Return a new XDM::Value from this Sequence with the passed in value
      # appended to the end.
      # @return [XDM::Value] the new Value
      def append(other)
        XDM::Value.create([self, other])
      end

      alias_method :<<, :append
      alias_method :+, :append
    end

    # Mixin for objects that are Sequence-like but only contain a single item,
    # like {XDM::AtomicValue} or {XDM::Node}
    module ItemSequenceLike
      # return a single-item Enumerator containing +self+
      def sequence_enum
        [self].to_enum
      end

      # Returns the sequence size, which will always be 1.
      def sequence_size
        1
      end
    end
  end
end