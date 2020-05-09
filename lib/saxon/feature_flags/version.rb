require_relative '../version/library'
require_relative 'errors'

module Saxon
  # Allows saxon-rb features to be switched off if they can't be used under one
  # of the otherwise-supported Saxon versions
  #
  # @api private
  module FeatureFlags
    class Version
      def self.create(klass, method_name, version_constraint)
        method = klass.instance_method(method_name)
        version_check = new(version_constraint)


        klass.send(:define_method, method_name, ->(*args) {
          if version_check.ok?
            klass.send(:define_method, method_name, method)
            method.bind(self).call(*args)
          else
            klass.send(:define_method, method_name, ->(*args) {
              raise UnavailableInThisSaxonVersionError
            })
            raise UnavailableInThisSaxonVersionError
          end
        })
      end

      attr_reader :constraint_string, :comparison_operator, :version_string

      def initialize(constraint_string)
        @constraint_string = constraint_string
        @comparison_operator, @version_string = parse_version_constraint(constraint_string)
      end

      def ok?
        Saxon::Version::Library.loaded_version.send(comparison_operator, constraint_version)
      end

      def constraint_version
        @constraint_version ||= begin
          components = version_string.split('.').map { |n| Integer(n, 10) }
          Saxon::Version::Library.new(version_string, components, 'HE')
        end
      end

      private

      def parse_version_constraint(version_constraint)
        op_string, version_string = version_constraint.split

        comparison_operator = parse_operator_string(op_string)
        [comparison_operator, version_string]
      end

      def parse_operator_string(op_string)
        case op_string
        when '~>'
          :pessimistic_compare
        else
          op_string.to_sym
        end
      end
    end
  end
end