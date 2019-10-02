require 'saxon/xdm/node'

module Saxon
  # Builds XDM objects from XML sources, for use in XSLT or for query and
  # access
  class DocumentBuilder
    # @api private
    # @param [net.sf.saxon.s9api.DocumentBuilder] s9_document_builder The
    # Saxon DocumentBuilder instance to wrap
    def initialize(s9_document_builder)
      @s9_document_builder = s9_document_builder
    end

    # @param [Saxon::Source] source The Saxon::Source containing the source
    #   IO/string
    # @return [Saxon::XDM::Node] The Saxon::XDM::Node representing the root of the
    #   document tree
    def build(source)
      XDM::Node.new(@s9_document_builder.build(source.to_java))
    end

    # @return [net.sf.saxon.s9api.DocumentBuilder] The underlying Java Saxon
    #   DocumentBuilder instance
    def to_java
      @s9_document_builder
    end
  end
end
