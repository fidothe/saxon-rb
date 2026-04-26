require 'uri'
require 'pathname'
require 'set'
require_relative '../item_type'

module Saxon
  class Configuration
    module FeatureValidator
      def valid?(value)
        raise NotImplementedError, "Subclasses must implement #valid?"
      end

      # A validator for features that take boolean values. This is Ruby, so we
      # allow any value, and conversion will make the truthiness explicit.
      class Boolean
        include FeatureValidator

        def valid?(value)
          true
        end
      end

      # A validator for features that take simple string values. This is Ruby, so
      # anything that responds to +to_s+ is valid.
      class SimpleString
        include FeatureValidator

        def valid?(value)
          value.respond_to?(:to_s)
        end
      end

      # A validator for features that take a specific set of string values.
      class StringSet
        include FeatureValidator

        attr_reader :allowed_values
        private :allowed_values

        def initialize(allowed_values)
          @allowed_values = allowed_values
        end

        def valid?(value)
          @allowed_values.include?(value)
        end
      end

      # A validator for features that take a class as a value, validating that the values
      # are a subclass or include the expected module.
      class ClassValidator
        include FeatureValidator

        def java_class
          @java_class ||= @java_class_lambda.call
        end
        private :java_class

        def initialize(java_class_lambda)
          @java_class_lambda = java_class_lambda
        end

        def valid?(value)
          java_class.is_assignable_from?(value.class)
        end
      end

      # A validator for features that take a class name as a value, with the expectation
      # that it will be loaded via reflection in Java.
      class ClassName
        include FeatureValidator

        def klass
          @klass ||= @klass_lambda.call
        end
        private :klass

        def initialize(klass_lambda)
          @klass_lambda = klass_lambda
        end

        def valid?(class_name)
          if class_name.include?('.')
            java_package_name_elements = class_name.split('.')
            actual_class_name = java_package_name_elements.pop
            package_name = java_package_name_elements.collect(&:capitalize).join
            begin
              return false unless Java.const_defined?(package_name)
              java_mod = Java.const_get(package_name)
              return false unless java_mod.const_defined?(actual_class_name)
              !!(java_mod.const_get(actual_class_name) <= klass)
            rescue NameError
              return false
            end
          else
            !!(Module.const_defined?(class_name) && Module.const_get(class_name) <= klass)
          end
        end
      end

      # A validator for features that take a simple integer value.
      class SimpleInteger
        include FeatureValidator

        def valid?(value)
          value.is_a?(Integer) || value.class.java_class === Java::JavaLang::Integer.java_class
        end
      end

      # A validator for features that take a URI value.
      class URI
        include FeatureValidator

        def valid?(value)
          case value
          when ::URI
            true
          when String
            begin
              uri = URI(value)
              !uri.scheme.nil?
            rescue ::URI::InvalidURIError
              false
            end
          else
            false
          end
        end
      end

      # A validator for features that take a filesystem path value. Accepts Ruby Pathname/File/Dir objects,
      # as well as strings that can be converted to valid paths.
      class Path
        include FeatureValidator

        def valid?(value)
          case value
          when Pathname, File, Dir
            true
          when String
            begin
              path = Pathname(value)
              true
            rescue ArgumentError
              false
            end
          else
            false
          end
        end
      end

      # A validator for features that take a set of flags represented as a string, where each character is a flag. The allowed
      # flags are specified as a string of allowed characters, and a specific string can be designated to indicate that no flags are set.
      class Flags
        include FeatureValidator

        attr_reader :allowed_flags, :no_flags_indicator

        def initialize(allowed_flags, no_flags_indicator)
          @allowed_flags = Set.new(allowed_flags.chars)
          @no_flags_indicator = no_flags_indicator
        end

        def valid?(value)
          return false unless value.respond_to?(:to_s)
          value_str = value.to_s

          value_str == no_flags_indicator || allowed_flags.superset?(Set.new(value_str.chars))
        end
      end

      # A validator for features that take a comma-separated list of integers.
      class CommaSeparatedIntegers
        include FeatureValidator

        def valid?(value)
          items = value.split(',')
          items.count > 1 && items.all? { |item| Integer(item, 10, exception: false) }
        end
      end

      # A validator for features that integers from a set of special values (a Java Enum).
      class NamedIntegers
        include FeatureValidator


        def allowed
          @allowed ||= @allowed_generator.call
        end

        def allowed_names
          @allowed_names ||= Set.new(allowed.keys)
        end

        def allowed_integers
          @allowed_integers ||= Set.new(allowed.values)
        end

        def initialize(allowed_generator)
          @allowed_generator = allowed_generator
        end

        def valid?(value)
          allowed_names.include?(value) || allowed_integers.include?(value)
        end
      end

      class IntegerSet
        include FeatureValidator

        attr_reader :allowed

        def initialize(allowed)
          @allowed = Set.new(allowed)
        end

        def valid?(value)
          allowed.include?(value)
        end
      end

      class ItemType
        include FeatureValidator

        def valid?(value)
          return true if value.is_a?(Saxon::ItemType)
          value.respond_to?(:to_s) && check_type(value.to_s)
        end

        private

        def check_type(type_string)
          begin
            !!Saxon::ItemType.get_type(type_string)
          rescue Saxon::ItemType::ItemTypeError
            false
          end
        end
      end
    end
  end
end