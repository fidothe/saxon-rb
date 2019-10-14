require_relative 'xdm/node'
require_relative 'xdm/atomic_value'
require_relative 'xdm/array'
require_relative 'xdm/map'
require_relative 'xdm/function_item'
require_relative 'xdm/external_object'
require_relative 'xdm/value'
require_relative 'xdm/empty_sequence'
require_relative 'xdm/item'

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

      def Array(*args)
        XDM::Array.create(*args)
      end
    end
  end
end
