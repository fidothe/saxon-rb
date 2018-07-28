require 'saxon/s9api'

module Saxon
  # Serialize XDM objects.
  class Serializer
    # Manage access to the serialization properties of this serializer, with
    # hash-like access.
    #
    # Properties can be set explicitly through this API, or via XSLT or XQuery
    # serialization options like `<xsl:output>`.
    #
    # Properties set explicitly here will override properties set through the
    # document like `<xsl:output>`.
    class OutputProperties
      # @api private
      # Provides mapping between symbols and the underlying Saxon property
      # instances
      def self.output_properties
        @output_properties ||= Hash[
          Saxon::S9API::Serializer::Property.values.map { |property|
            qname = property.getQName
            key = [
              qname.getPrefix,
              qname.getLocalName.tr('-', '_')
            ].reject { |str| str == '' }.join('_').to_sym
            [key, property]
          }
        ]
      end

      attr_reader :s9_serializer

      # @api private
      def initialize(s9_serializer)
        @s9_serializer = s9_serializer
      end

      # @param [Symbol, Saxon::S9API::Serializer::Property] property The property to fetch
      def [](property)
        s9_serializer.getOutputProperty(resolved_property(property))
      end

      # @param [Symbol, Saxon::S9API::Serializer::Property] property The property to set
      # @param [String] value The string value of the property
      def []=(property, value)
        s9_serializer.setOutputProperty(resolved_property(property), value)
      end

      private
      def resolved_property(property_key)
        case property_key
        when Symbol
          self.class.output_properties.fetch(property_key)
        else
          property_key
        end
      end
    end

    attr_reader :s9_serializer
    private :s9_serializer

    # @api private
    def initialize(s9_serializer)
      @s9_serializer = s9_serializer
    end

    # @return [Saxon::Serializer::OutputProperties] hash-like access to the Output Properties
    def output_property
      @output_property ||= OutputProperties.new(s9_serializer)
    end

    # Serialize an XdmNode to an IO
    #
    # @param [Saxon::XdmNode] xdm_node The XdmNode to serialize
    # @param [File, IO] io The IO to serialize to
    def serialize(xdm_node, io)
      s9_serializer.setOutputStream(io.to_outputstream)
      s9_serializer.serializeNode(xdm_node.to_java)
    end

    # @return [Saxon::S9API::Serializer] The underlying Saxon Serializer object
    def to_java
      s9_serializer
    end
  end
end

