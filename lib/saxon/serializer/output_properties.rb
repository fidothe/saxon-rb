module Saxon
  module Serializer
    # Manage access to the serialization properties of this serializer, with
    # hash-like access.
    #
    # Properties can be set explicitly through this API, or via XSLT or XQuery
    # serialization options like +<xsl:output>+.
    #
    # Properties set explicitly here will override properties set through the
    # document by +<xsl:output>+.
    module OutputProperties
      # @return [Saxon::Serializer::OutputProperties] hash-like access to the Output Properties
      def output_property
        @output_property ||= OutputProperties::Accessor.new(s9_serializer)
      end

      # @api private
      #
      # The private wrapper class that manages getting and setting output
      # properties on a Serializer in an idiomatic Ruby-like way.
      class Accessor
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
    end
  end
end