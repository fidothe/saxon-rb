require_relative '../version/library'
require_relative 'errors'

module Saxon
  module FeatureFlags
    # Restrict a specific method to only work with the specified Saxon version
    class Version
      # Modify the method so that it will only run if the version constraint is
      # satisfied.
      #
      # We can't know what version of Saxon is in use at code load time, only
      # once {Saxon::Loader#load!} has been called, either explicitly or by
      # calling a method which requires a Saxon Java object. Therefore, we have
      # to check this the first time someone calls the method.
      #
      # Creating this check replaces the method on the target class with one
      # that checks the version, and runs the original version if its constraint
      # is satisfied.
      #
      # To avoid performing the check every time the method is called, once we
      # know whether or not the constraint is satisfied, we assume that the
      # verion of Saxon cannot be unloaded and a new one loaded in its place and
      # replace our version checking method with the original (if the constraint
      # is passed), or with one that simply +raise+s the constraint error.
      #
      # @param klass [Class] the class the method lives on
      # @param method_name [Symbol] the name of the method to be constrained
      # @param version_constraint [String] the version constraint
      #   (<tt>'>9.9.1.7'</tt> or <tt>'>= 9.9'</tt>)
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