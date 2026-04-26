require_relative '../s9api'
require_relative './feature_validator'
require_relative './feature_data_map'

module Saxon
  class Configuration
    class Feature
      class << self
        def all
          @all ||= get_features
        end

        def by_name(name)
          @all_by_name ||= all.map { |feature| [feature.name, feature] }.to_h
          @all_by_name[name]
        end

        def by_uri(uri)
          @all_by_uri ||= all.map { |feature| [feature.uri, feature] }.to_h
          @all_by_uri[uri.to_s]
        end

        def get(name_or_uri)
          by_name(name_or_uri) || by_uri(name_or_uri) || (raise NameError, "Feature not found: #{name_or_uri}")
        end

        private

        def get_features
          Saxon::S9API::FeatureKeys.java_class.fields.select { |field|
            Saxon::S9API::FeatureIndex.exists(field.static_value)
          }.map { |field|
            data = Saxon::S9API::FeatureIndex.getData(field.static_value)
            s9feature = Saxon::S9API::Feature.const_get(field.name)
            new(field.name.downcase.to_sym, data.uri, s9feature, setter_for(data), getter_for(data), validator_for(data), default_value_for(data))
          }
        end

        def validator_for(feature_data)
          Saxon::Configuration::FeatureDataMap.validator_for(feature_data)
        end

        def setter_for(feature_data)
          Saxon::Configuration::FeatureDataMap.setter_for(feature_data)
        end

        def getter_for(feature_data)
          Saxon::Configuration::FeatureDataMap.getter_for(feature_data)
        end

        def default_value_for(feature_data)
          feature_data.defaultValue
        end
      end

      attr_reader :name, :uri, :s9feature, :setter, :getter, :validator, :default_value

      def initialize(name, uri, s9feature, setter, getter, validator, default_value)
        @name = name
        @uri = uri
        @s9feature = s9feature
        @setter = setter
        @getter = getter
        @validator = validator
        @default_value = default_value
      end

      def set(s9config, value)
        unless validator.valid?(value)
          raise ArgumentError, "Invalid value #{value.inspect} for feature #{name}"
        end

        s9config.setConfigurationProperty(s9feature, setter.call(value))
      end

      def get(s9config)
        getter.call(s9config.getConfigurationProperty(s9feature))
      end
    end
  end
end