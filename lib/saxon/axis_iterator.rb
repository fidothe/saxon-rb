require_relative 's9api'

module Saxon
  # An iterator across an XPath axis of an XDM document, e.g. down to children
  # (+child+), up to the root (+ancestor+)
  # @example iterate over child nodes
  #   AxisIterator.new(node, :child).each do |child_node|
  #     puts child_node.node_name
  #   end
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

    # yields each node in the sequence
    # @yieldparam [Saxon::XDM::Node] the next node in the sequence
    def each(&block)
      s9_sequence_iterator.lazy.map { |s9_xdm_node| Saxon::XDM::Node.new(s9_xdm_node) }.each(&block)
    end

    private

    def s9_sequence_iterator
      s9_xdm_node.axisIterator(s9_axis)
    end
  end
end
