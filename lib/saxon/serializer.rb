require 'saxon/s9api'
require 'stringio'

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

      # @overload fetch(property)
      #   @param [Symbol, Saxon::S9API::Serializer::Property] property The property to fetch
      # @overload fetch(property, default)
      #   @param property [Symbol, Saxon::S9API::Serializer::Property] The property to fetch
      #   @param default [Object] The value to return if the property is unset
      def fetch(property, default = nil)
        explicit_value = self[property]
        if explicit_value.nil? && !default.nil?
          default
        else
          explicit_value
        end
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
      file = Java::JavaIO::File.new(path)
      s9_serializer.setOutputFile(file)
      s9_serializer.serializeXdmValue(xdm_value.to_java)
      nil
    end
  end
end

