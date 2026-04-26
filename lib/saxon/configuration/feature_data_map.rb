require_relative './feature_setter'
require_relative './feature_getter'

module Saxon
  class Configuration
    module FeatureDataMap
      class << self
        #  #<Java::JavaLang::Class: java.lang.Object>,

#         {"http://saxon.sf.net/feature/messageEmitterClass" => #<Java::NetSfSaxonLib::FeatureData:0x21caabec>,

        def generic_setter
          @generic_setter ||= FeatureSetter::Generic.new
        end

        def generic_getter
          @generic_getter ||= FeatureGetter::Generic.new
        end

        def boolean_validator
          @boolean_validator ||= FeatureValidator::Boolean.new
        end

        def boolean_setter
          @boolean_setter ||= FeatureSetter::Boolean.new
        end

        def boolean_getter
          @boolean_getter ||= FeatureGetter::Boolean.new
        end

        def string_validator
          @string_validator ||= FeatureValidator::SimpleString.new
        end

        def string_getter
          @string_getter ||= FeatureGetter::String.new
        end

        def integer_validator
          @integer_validator ||= FeatureValidator::SimpleInteger.new
        end

        def uri_validator
          @uri_validator ||= FeatureValidator::URI.new
        end

        def uri_setter
          @uri_setter ||= FeatureSetter::URI.new
        end

        def uri_getter
          @uri_getter ||= FeatureGetter::URI.new
        end

        def path_validator
          @path_validator ||= FeatureValidator::Path.new
        end

        def path_setter
          @path_setter ||= FeatureSetter::Path.new
        end

        def klass_setter
          @klass_setter ||= FeatureSetter::Klass.new
        end

        def special_mappings
          @special_mappings ||= {
            "http://saxon.sf.net/feature/occurrenceLimits" => FeatureValidator::CommaSeparatedIntegers.new,
            "http://saxon.sf.net/feature/optimizationLevel" => FeatureValidator::Flags.new("cefgjklmnrsvwx", "0"),
            "http://saxon.sf.net/feature/defaultRegexEngine" => FeatureValidator::StringSet.new(["S", "J"]),
            "http://saxon.sf.net/feature/xqueryDefaultElementNamespace" => uri_validator,
            "http://saxon.sf.net/feature/xqueryDefaultFunctionNamespace" => uri_validator,
            "http://saxon.sf.net/feature/allowedProtocols" => string_validator,
            "http://saxon.sf.net/feature/messageEmitterClass" => string_validator,
            "http://saxon.sf.net/feature/resourceResolver" =>
              FeatureValidator::ClassValidator.new(->() { Java::NetSfSaxonLib::ResourceResolver }), # Indirection to postpone loading until Saxon has been required
            "http://saxon.sf.net/feature/defaultCollation" => uri_validator,
            "http://saxon.sf.net/feature/licenseFileLocation" => path_validator,
            "http://saxon.sf.net/feature/schema-validation" => FeatureValidator::NamedIntegers.new(->() {
              {
                strict: Java::NetSfSaxonLib::Validation.STRICT,
                lax: Java::NetSfSaxonLib::Validation.LAX,
                preserve: Java::NetSfSaxonLib::Validation.PRESERVE,
                strip: Java::NetSfSaxonLib::Validation.STRIP
              }
            }),
          }
        end

        def special_setter_mappings
          @special_setter_mappings ||= {
            "http://saxon.sf.net/feature/xqueryDefaultElementNamespace" => uri_setter,
            "http://saxon.sf.net/feature/xqueryDefaultFunctionNamespace" => uri_setter,
            "http://saxon.sf.net/feature/defaultCollation" => uri_setter,
            "http://saxon.sf.net/feature/licenseFileLocation" => path_setter,
          }
        end

        def setter_for(feature_data)
          if special_setter_mappings.key?(feature_data.uri)
            return special_setter_mappings[feature_data.uri]
          end

          case feature_data.type
          when Java::JavaLang::Boolean.java_class
            boolean_setter
          when Java::JavaLang::String.java_class, Java::JavaLang::Integer.java_class
            generic_setter
          else
            klass_setter
          end
        end

        def special_getter_mappings
          @special_getter_mappings ||= {
            "http://saxon.sf.net/feature/xqueryDefaultElementNamespace" => uri_getter,
            "http://saxon.sf.net/feature/xqueryDefaultFunctionNamespace" => uri_getter,
            "http://saxon.sf.net/feature/defaultCollation" => uri_getter,
          }
        end

        # TODO the conversion of feature values into Ruby values is a little half-baked
        def getter_for(feature_data)
          if special_getter_mappings.key?(feature_data.uri)
            return special_getter_mappings[feature_data.uri]
          end

          case feature_data.type
          when Java::JavaLang::Boolean.java_class
            boolean_getter
          else
            generic_getter
          end
        end

        def validator_for(feature_data)
          if special_mappings.key?(feature_data.uri)
            return special_mappings[feature_data.uri]
          end

          case feature_data.type
          when Java::JavaLang::Boolean.java_class
            boolean_validator
          when Java::JavaLang::String.java_class
            string_validator
          when Java::JavaLang::Integer.java_class
            integer_validator
          else
            FeatureValidator::ClassValidator.new(-> () { feature_data.type })
          end
        end
      end
    end
  end
end
