require_relative '../serializer'
require_relative '../xdm/value'


module Saxon
  module XSLT
    # Represents the invocation of a compiled and loaded transformation,
    # providing an idiomatic way to send the result a transformation to a
    # particular Destination, or to serialize it directly to a file, string, or
    # IO.
    class Invocation
      attr_reader :s9_transformer, :invocation_lambda
      private :s9_transformer, :invocation_lambda

      # @api private
      def initialize(s9_transformer, invocation_lambda, raw)
        @s9_transformer, @invocation_lambda, @raw = s9_transformer, invocation_lambda, raw
      end

      # Serialize the result to a string using the options specified in
      # +<xsl:output/>+ in the XSLT
      #
      # @return [String] the serialized result of the transformation
      def to_s
        serializer_destination.serialize
      end

      # Serialize the result of the transformation. When called with a
      # block, the block will be executed via instance-exec so that output
      # properties can be set, e.g.
      #
      #     result.serialize {
      #       output_property[:indent] = 'yes'
      #     }
      #
      # @overload serialize(io)
      #   Serialize the transformation to an IO
      #   @param [File, IO] io The IO to serialize to
      #   @return [nil]
      #   @yield the passed block bound via instance-exec to the new serializer
      # @overload serialize(path)
      #   Serialize the transformation to file <tt>path</tt>
      #   @param [String, Pathname] path The path of the file to serialize to
      #   @return [nil]
      #   @yield the passed block bound via instance-exec to the new serializer
      # @overload serialize
      #   Serialize the transformation to a String
      #   @return [String] The serialized XdmValue
      def serialize(path_or_io = nil, &block)
        serializer_destination(&block).serialize(path_or_io)
      end

      # Return the result of the transformation as an XDM Value, either as it is
      # returned (if the XSLT::Executable was created with :raw => true), or
      # wrapped in a Document node and sequence normalized.
      #
      # @return [Saxon::XDM::Value] the XDM value returned by the transformation
      def xdm_value
        if raw?
          XDM.Value(invocation_lambda.call(nil))
        else
          invocation_lambda.call(s9_xdm_destination)
          XDM.Value(s9_xdm_destination.getXdmNode)
        end
      end

      # Send the result of the transformation to the supplied Destination
      #
      # @param s9_destination [net.sf.saxon.s9api.Destination] the Saxon
      #   destination to use
      # @return [nil]
      def to_destination(s9_destination)
        invocation_lambda.call(s9_destination)
        nil
      end

      # Whether the transformation was invoked as a 'raw' transformation, where
      # an XDM Value result will be returned without being wrapped in a Document
      # node, and without sequence normalization.
      #
      # @return [Boolean] whether the transformation was invoked 'raw' or not
      def raw?
        @raw
      end

      private

      def serializer_destination(&block)
        Saxon::Serializer::Destination.new(s9_transformer.newSerializer, invocation_lambda, &block)
      end

      def s9_xdm_destination
        @s9_xdm_destination ||= Saxon::S9API::XdmDestination.new
      end
    end
  end
end