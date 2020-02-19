require_relative '../s9api'
require_relative './output_properties'

module Saxon
  module Serializer
    # A Saxon Serializer to be used as a Destination for a transformation rather
    # than being directly called with existing XDM objects
    class Destination
      include OutputProperties

      attr_reader :s9_serializer, :invocation_lambda

      # @api private
      def initialize(s9_serializer, invocation_lambda, &block)
        @s9_serializer, @invocation_lambda = s9_serializer, invocation_lambda
        if block_given?
          instance_exec(&block)
        end
      end

      # @overload serialize(io)
      #   Serialize the transformation to an IO
      #   @param [File, IO] io The IO to serialize to
      #   @return [nil]
      # @overload serialize(path)
      #   Serialize the transformation to file <tt>path</tt>
      #   @param [String, Pathname] path The path of the file to serialize to
      #   @return [nil]
      # @overload serialize
      #   Serialize the transformation to a String
      #   @return [String] The serialized XdmValue
      def serialize(io_or_path = nil)
        case io_or_path
        when nil
          serialize_to_string
        when String, Pathname
          serialize_to_file(io_or_path)
        else
          serialize_to_io(io_or_path)
        end
      end

      # @return [Saxon::S9API::Serializer] The underlying Saxon Serializer object
      def to_java
        s9_serializer
      end

      private

      def run_transform!
        invocation_lambda.call(self.to_java)
      end

      def serialize_to_string
        str_encoding = output_property.fetch(:encoding, Encoding.default_internal || Encoding.default_external)
        StringIO.open { |io|
          io.binmode
          set_output_io(io)
          run_transform!
          io.string.force_encoding(str_encoding)
        }
      end

      def serialize_to_io(io)
        set_output_io(io)
        run_transform!
      end

      def set_output_io(io)
        s9_serializer.setOutputStream(io.to_outputstream)
      end

      def serialize_to_file(path)
        file = Java::JavaIO::File.new(path.to_s)
        s9_serializer.setOutputFile(file)
        run_transform!
      end
    end
  end
end