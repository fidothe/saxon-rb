module Saxon
  module FeatureFlags
    module Helpers
      def requires_saxon_version(method_name, version_constraint)
        Saxon::FeatureFlags::Version.create(self, method_name, version_constraint)
      end
    end
  end
end