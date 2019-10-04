require_relative 'xdm/node'
require_relative 'xdm/atomic_value'
require_relative 'xdm/value'
require_relative 'xdm/empty_sequence'

module Saxon
  module XDM
    class << self
      def AtomicValue(*args)
        XDM::AtomicValue.create(*args)
      end

      def Value(*args)
        XDM::Value.create(*args)
      end

      def EmptySequence()
        XDM::EmptySequence.create
      end
    end
  end
end
