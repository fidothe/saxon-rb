module Saxon
  module FeatureFlags
    # Error raised if a feature is not available under the loaded version of
    # Saxon
    class UnavailableInThisSaxonVersionError < StandardError
    end
  end
end