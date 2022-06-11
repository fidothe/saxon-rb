require_relative '../version/library'
require_relative 'errors'

module Saxon
  module FeatureFlags
    # Restrict a specific method to only work with the specified Saxon version
    class Version
      # @return [String] the complete constraint string
      attr_reader :constraint_string
      # @return [Symbol] the extracted comparison operator
      attr_reader :comparison_operator
      # @return [String] the extracted version string
      attr_reader :version_string

      # Create a version constraint check from the supplied constraint string
      #
      # @param constraint_string [String] the version constraint
      def initialize(constraint_string)
        @constraint_string = constraint_string
        @comparison_operator, @version_string = parse_version_constraint(constraint_string)
      end

      # Reports if the version constraint is satisfied or not.
      #
      # @return [Boolean] true if the constraint is satisfied, false otherwise
      def ok?
        Saxon::Version::Library.loaded_version.send(comparison_operator, constraint_version)
      end

      # Generates a {Saxon::Version::Library} representing the version specified
      # in the constraint that can be compared with the loaded Saxon version
      #
      # @return [Saxon::Version::Library] the constraint version
      def constraint_version
        @constraint_version ||= Saxon::Version::Library.new(version_string, 'HE')
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