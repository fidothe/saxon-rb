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
  # Classes for representing, creating, and working with the XPath Data Model
  # type system used in XPath 2+, XSLT 2+, and XQuery.
  module XDM
    class << self
      # Convenience function for creating a new {AtomicValue}. See {AtomicValue.create}
      def AtomicValue(*args)
        XDM::AtomicValue.create(*args)
      end

      # Convenience function for creating a new {Value}. See {Value.create}
      def Value(*args)
        XDM::Value.create(*args)
      end

      # Returns the XDM {EmptySequence}. See {EmptySequence.create}
      def EmptySequence()
        XDM::EmptySequence.create
      end

      # Convenience function for creating a new {Array}. See {Array.create}
      def Array(*args)
        XDM::Array.create(*args)
      end

      # Convenience function for creating a new {Map}. See {Map.create}
      def Map(*args)
        XDM::Map.create(*args)
      end
    end
  end
end
