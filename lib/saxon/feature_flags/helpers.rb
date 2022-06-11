module Saxon
  module FeatureFlags
    # Helper methods to create feature restrictions in the library. To be mixed
    # in to library classes.
    module Helpers
      # specify that the method named can only run if the version constraint is satisfied
      #
      # @param method_name [Symbol] the name of the method
      # @param version_constraint [String] the version constraint (<tt>'>= 9.9'</tt>)
      def requires_saxon_version(method_name, version_constraint)
        Saxon::FeatureFlags::Method.critical(self, method_name, version_constraint)
      end

      def requires_saxon_version_or_noop(method_name, version_constraint)
        Saxon::FeatureFlags::Method.noop(self, method_name, version_constraint)
      end

      def class_requires_saxon_version(klass, version_constraint)
        Saxon::FeatureFlags::Class.critical(klass, version_constraint)
      end
    end
  end
end