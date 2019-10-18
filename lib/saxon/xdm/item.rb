module Saxon
  module XDM
    def self.Item(item)
      case item
      when Value, AtomicValue, Node, Array, Map, ExternalObject
        item
      when Saxon::S9API::XdmNode
        Node.new(item)
      when Saxon::S9API::XdmAtomicValue
        AtomicValue.new(item)
      when Saxon::S9API::XdmExternalObject
        ExternalObject.new(item)
      when Saxon::S9API::XdmArray
        Array.new(item)
      when Saxon::S9API::XdmMap
        Map.new(item)
      when Saxon::S9API::XdmValue
        Value.new(item)
      when ::Array
        Array.create(item)
      when ::Hash
        Map.create(item)
      else
        if item.respond_to?(:each)
          Array.create(item)
        else
          AtomicValue.create(item)
        end
      end
    end
  end
end
