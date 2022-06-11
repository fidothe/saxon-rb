require_relative 'feature_flags/version'
require_relative 'feature_flags/helpers'
require_relative 'feature_flags/method'
require_relative 'feature_flags/class'

module Saxon
  # Allows saxon-rb features to be switched off if they can't be used under one
  # of the otherwise-supported Saxon versions
  #
  # @api private
  module FeatureFlags
    def self.class_requires_saxon_version(klass, version_constraint)

    end
  end
end