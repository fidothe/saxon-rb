require 'saxon/xslt'

module Saxon
  module XSLT
    class Executable
      # Provided for Nokogiri API compatibility. Cannot use many XSLT 2 and 3
      # features as a result.
      #
      # Transform the input document by applying templates as in XSLT 1. All
      # parameters will be interpreted as Strings
      #
      # @param doc_node [Saxon::XDM::Node] the document to transform
      # @param params [Hash, Array] a Hash of param name => value, or an Array
      #   of param names and values of the form +['param', 'value', 'param2',
      #   'value']+. The array must be of an even-numbered length
      # @return [Saxon::XDM::Value] the result document
      def transform(doc_node, params = {})
        apply_templates(doc_node, v1_parameters(params)).xdm_value
      end

      # Provided for Nokogiri API compatibility. Cannot use many XSLT 2 and 3
      # features as a result.
      #
      # Transform the input document by applying templates as in XSLT 1, and
      # then serializing the result to a string using the serialization options
      # set in the XSLT stylesheet's +<xsl:output/>+.
      #
      # @param doc_node [Saxon::XDM::Node] the document to transform
      # @param params [Hash, Array] a Hash of param name => value, or an Array
      #   of param names and values of the form +['param', 'value', 'param2',
      #   'value']+. The array must be of an even-numbered length
      # @return [String] a serialization of the the result document
      def apply_to(doc_node, params = {})
        apply_templates(doc_node, v1_parameters(params)).to_s
      end

      # Provided for Nokogiri API compatibility. Cannot use many XSLT 2 and 3
      # features as a result.
      #
      # Serialize the input document to a string using the serialization options
      # set in the XSLT stylesheet's +<xsl:output/>+.
      #
      # @param doc_node [Saxon::XDM::Node] the document to serialize
      # @return [String] a serialization of the the input document
      def serialize(doc_node)
        s9_transformer = @s9_xslt_executable.load30
        serializer = Saxon::Serializer::Object.new(s9_transformer.newSerializer)
        serializer.serialize(doc_node.to_java)
      end

      private

      def v1_parameters(params = [])
        v1_params = v1_params_hash(params).map { |qname, value|
          [Saxon::QName.resolve(qname), Saxon::XDM.AtomicValue(v1_param_value(value))]
        }.to_h
        return {} if v1_params.empty?
        {global_parameters: v1_params}
      end

      def v1_params_hash(params = [])
        return params if params.is_a?(Hash)
        params.each_slice(2).map { |k,v|
          raise ArgumentError.new("Odd number of values passed as params: #{params}") if v.nil?
          [k, v]
        }.to_h
      end

      def v1_param_value(value)
        if /\A(['"]).+\1\z/.match(value)
          value.slice(1..-2)
        else
          value
        end
      end
    end
  end
end