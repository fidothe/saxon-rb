module Saxon
  module XDM
    # Create one of the XdmItem-derived XDM objects from the passed in argument.
    #
    # Existing XDM::* objects are passed through. s9api.Xdm* Java objects are
    # wrapped appropriately and returned. Ruby Arrays and Hashes are converted
    # to {XDM::Array} and {XDM::Map} instances respectively. Ruby values that
    # respond to +#each+ are converted to an {XDM::Array} (e.g. {Set}). Other
    # Ruby values are converted to {XDM::AtomicValue}.
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
