module Saxon
  module XDM
    module SequenceLike
      def sequence_enum
        raise NotImplementedError
      end

      def sequence_size
        raise NotImplementedError
      end

      def append(other)
        XDM::Value.create([self, other])
      end

      alias_method :<<, :append
      alias_method :+, :append
    end
  end
end