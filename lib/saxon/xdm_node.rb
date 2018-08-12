require_relative 'axis_iterator'

module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element or one of the other node chunks in the XDM.
  class XdmNode
    include Enumerable

    attr_reader :s9_xdm_node
    private :s9_xdm_node

    # @api private
    def initialize(s9_xdm_node)
      @s9_xdm_node = s9_xdm_node
    end

    # @return [Saxon::S9API::XdmNode] The underlying Saxon Java XDM node object.
    def to_java
      @s9_xdm_node
    end

    def node_name
      return @node_name if instance_variable_defined?(:@node_name)
      node_name = s9_xdm_node.getNodeName
      @node_name = node_name.nil? ? nil : Saxon::QName.new(node_name)
    end

    def ==(other)
      return false unless other.is_a?(XdmNode)
      s9_xdm_node.equals(other.to_java)
    end

    alias_method :eql?, :==

    def hash
      @hash ||= s9_xdm_node.hashCode
    end

    def each(&block)
      axis_iterator(:child).each(&block)
    end

    def axis_iterator(axis)
      AxisIterator.new(self, axis)
    end
  end
end
