require_relative 'static_context'
require_relative '../serializer'
require_relative '../xdm_node'

module Saxon
  module XSLT
    # Represents a compiled XPaGth query ready to be executed
    class Executable
      # @return [XSLT::StaticContext] the XPath's static context
      attr_reader :static_context

      # @api private
      # @param s9_xslt_executable [net.sf.saxon.s9api.XsltExecutable] the
      #   Saxon compiled XPath object
      # @param static_context [XPath::StaticContext] the XPath's static
      #   context
      def initialize(s9_xslt_executable, static_context)
        @s9_xslt_executable, @static_context = s9_xslt_executable, static_context
      end

      def apply_templates(starting_context)
        transformer = @s9_xslt_executable.load30
        destination = Saxon::S9API::XdmDestination.new
        transformer.applyTemplates(starting_context.to_java, destination)
        Result.new(XdmNode.new(destination.getXdmNode), transformer)
      end

      # @return [net.sf.saxon.s9api.XsltExecutable] the underlying Saxon
      #   <tt>XsltExecutable</tt>
      def to_java
        @s9_xslt_executable
      end
    end

    class Result
      attr_reader :xdm_node

      def initialize(xdm_node, s9_transformer)
        @xdm_node, @s9_transformer = xdm_node, s9_transformer
      end

      def to_s
        serializer = Serializer.new(@s9_transformer.newSerializer)
        serializer.serialize(@xdm_node)
      end
    end
  end
end
