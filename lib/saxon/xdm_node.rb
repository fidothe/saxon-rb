module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element or one of the other node chunks in the XDM.
  class XdmNode
    # @api private
    def initialize(s9_xdm_node)
      @s9_xdm_node = s9_xdm_node
    end

    # @return [Saxon::S9API::XdmNode] The underlying Saxon Java XDM node object.
    def to_java
      @s9_xdm_node
    end
  end
end
