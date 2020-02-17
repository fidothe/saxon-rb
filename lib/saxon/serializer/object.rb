require_relative '../s9api'
require_relative './output_properties'
require 'stringio'

module Saxon
  module Serializer
    # A Saxon Serializer to be used directly with XDM Values rather than being
    # called as a Destination for a transformation.
    class Object
      # Create a serializer from the passed in +Processor+. When called with a
      # block, the block will be executed via instance-exec so that output
      # properties can be set, e.g.
      #
      #     Serializer::Object.create(processor) {
      #       output_property[:indent] = 'yes'
      #     }
      #
      # @param processor [Saxon::Processor] the processor to create this
      #   +Serializer::Object+ from
      # @yield the passed block bound via instance-exec to the new serializer
      def self.create(processor, &block)
        new(processor.to_java.newSerializer, &block)
      end

      include OutputProperties

      attr_reader :s9_serializer
      private :s9_serializer

      # @api private
      def initialize(s9_serializer, &block)
        @s9_serializer = s9_serializer
        if block_given?
          instance_exec(&block)
        end
      end

      # @overload serialize(xdm_value, io)
      #   Serialize an XdmValue to an IO
      #   @param [Saxon::XdmValue] xdm_value The XdmValue to serialize
      #   @param [File, IO] io The IO to serialize to
      #   @return [nil]
      # @overload serialize(xdm_value, path)
      #   Serialize an XdmValue to file <tt>path</tt>
      #   @param [Saxon::XdmValue] xdm_value The XdmValue to serialize
      #   @param [String, Pathname] path The path of the file to serialize to
      #   @return [nil]
      # @overload serialize(xdm_value)
      #   Serialize an XdmValue to a String
      #   @param [Saxon::XdmValue] xdm_value The XdmValue to serialize
      #   @return [String] The serialized XdmValue
      def serialize(xdm_value, io_or_path = nil)
        case io_or_path
        when nil
          serialize_to_string(xdm_value)
        when String, Pathname
          serialize_to_file(xdm_value, io_or_path)
        else
          serialize_to_io(xdm_value, io_or_path)
        end
      end

      # @return [Saxon::S9API::Serializer] The underlying Saxon Serializer object
      def to_java
        s9_serializer
      end

      private

      def serialize_to_io(xdm_value, io)
        s9_serializer.setOutputStream(io.to_outputstream)
        s9_serializer.serializeXdmValue(xdm_value.to_java)
        nil
      end

      def serialize_to_string(xdm_value)
        str_encoding = output_property.fetch(:encoding, Encoding.default_internal || Encoding.default_external)
        StringIO.open { |io|
          io.binmode
          serialize_to_io(xdm_value, io)
          io.string.force_encoding(str_encoding)
        }
      end

      def serialize_to_file(xdm_value, path)
        file = Java::JavaIO::File.new(path.to_s)
        s9_serializer.setOutputFile(file)
        s9_serializer.serializeXdmValue(xdm_value.to_java)
        nil
      end
    end
  end
end