require 'uri'
require 'pathname'

module Saxon
  class Configuration
    module FeatureGetter
      def call(value)
        raise NotImplementedError, "Subclasses must implement #call"
      end

      class Boolean
        include FeatureGetter

        def call(value)
          value
        end
      end

      class Generic
        include FeatureGetter

        def call(value)
          value.to_s
        end
      end

      class URI
        include FeatureGetter

        def call(value)
          URI(value.to_s)
        end
      end
    end
  end
end
