require_relative 'feature_flags/version'
require_relative 'feature_flags/helpers'

module Saxon
  # Allows saxon-rb features to be switched off if they can't be used under one
  # of the otherwise-supported Saxon versions
  #
  # @api private
  module FeatureFlags
  end
end