require_relative '../axis_iterator'
require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # An XPath Data Model Node object, representing an XML document, or an
    # element or one of the other node chunks in the XDM.
    class Node
      include XDM::SequenceLike
      include XDM::ItemSequenceLike
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

      # The name of the node, as a {Saxon::QName}, or +nil+ if the node is not
      # of a kind that has a name
      # @return [Saxon::QName, null] the name, if there is one
      def node_name
        return @node_name if instance_variable_defined?(:@node_name)
        node_name = s9_xdm_node.getNodeName
        @node_name = node_name.nil? ? nil : Saxon::QName.new(node_name)
      end

      # What kind of node this is. Returns one of +:document+, +:element+,
      # +:text+, +:attribute+, +:namespace+, +:comment+,
      # +:processing_instruction+, or +:comment+
      #
      # @return [Symbol] the kind of node this is
      def node_kind
        @node_kind ||= case s9_xdm_node.nodeKind
        when Saxon::S9API::XdmNodeKind::ELEMENT
          :element
        when Saxon::S9API::XdmNodeKind::TEXT
          :text
        when Saxon::S9API::XdmNodeKind::ATTRIBUTE
          :attribute
        when Saxon::S9API::XdmNodeKind::NAMESPACE
          :namespace
        when Saxon::S9API::XdmNodeKind::COMMENT
          :comment
        when Saxon::S9API::XdmNodeKind::PROCESSING_INSTRUCTION
          :processing_instruction
        when Saxon::S9API::XdmNodeKind::DOCUMENT
          :document
        end
      end

      # Does this Node represent the same underlying node as the other?
      def ==(other)
        return false unless other.is_a?(XDM::Node)
        s9_xdm_node.equals(other.to_java)
      end

      alias_method :eql?, :==

      # Compute a hash-code for this {Node}.
      #
      # Two {Node}s with the same content will have the same hash code (and will compare using eql?).
      # @see Object#hash
      def hash
        @hash ||= s9_xdm_node.hashCode
      end

      # Execute the given block for every child node of this
      # @yieldparam node [Saxon::XDM::Node] the child node
      def each(&block)
        axis_iterator(:child).each(&block)
      end

      # Create an {AxisIterator} over this Node for the given XPath axis
      # @param axis [Symbol] the axis to iterate along
      # @see AxisIterator
      def axis_iterator(axis)
        AxisIterator.new(self, axis)
      end

      # Use Saxon's naive XDM Node serialisation to serialize the node and its
      # descendants. Saxon uses a new Serializer with default options to
      # serialize the node. In particular, if the Node was produced by an XSLT
      # that used +<xsl:character-map>+ through +<xsl:output>+ to modify the
      # contents, then they *WILL* *NOT* have been applied.
      #
      # +<xsl:output>+ has its effect at serialization time, not at XDM tree
      # creation time, so it won't be applied until you serialize the document.
      #
      # Even then, unless you use a {Serializer} configured with the XSLT's
      # +<xsl:output>+. We make a properly configured serializer available in
      # the result of any XSLT transform (a {Saxon::XSLT::Invocation}), e.g.:
      #
      #   result = xslt.apply_templates(input)
      #   result.to_s
      #   # or
      #   result.serialize('/path/to/output.xml')
      #
      # You can also get that {Serializer} directly from {XSLT::Executable},
      # should you want to use the serialization options from a particular XSLT
      # to serialize arbitrary XDM values:
      #
      #   serializer = xslt.serializer
      #   serializer.serialize(an_xdm_value)
      #
      # @see http://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/XdmNode@toString
      def to_s
        s9_xdm_node.toString
      end
    end
  end
end