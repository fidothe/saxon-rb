require 'saxon/s9api'
require 'saxon/xdm_node'

module Saxon
  # An XPath Data Model Node object, representing an XML document, or an element or one of the other node chunks in the XDM.
  class AxisIterator
    include Enumerable

    attr_reader :s9_xdm_node, :s9_axis
    private :s9_xdm_node, :s9_axis

    def initialize(xdm_node, axis)
      @s9_xdm_node = xdm_node.to_java
      @s9_axis = Saxon::S9API::Axis.const_get(axis.to_s.upcase.to_sym)
    end

    # @return [Saxon::S9API::XdmSequenceIterator] A new Saxon Java XDM sequence iterator.
    def to_java
      s9_sequence_iterator
    end

    def each(&block)
      s9_sequence_iterator.lazy.map { |s9_xdm_node| Saxon::XdmNode.new(s9_xdm_node) }.each(&block)
    end

    private

    def s9_sequence_iterator
      s9_xdm_node.axisIterator(s9_axis)
    end
  end
end
