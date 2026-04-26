require 'uri'
require 'pathname'

module Saxon
  class Configuration
    module FeatureSetter
      def call(value)
        raise NotImplementedError, "Subclasses must implement #call"
      end


      class Boolean
        include FeatureSetter

        def call(value)
          !!value
        end
      end

      class Generic
        include FeatureSetter

        def call(value)
          value.to_s
        end
      end

      class Klass
        include FeatureSetter

        def call(value)
          value.to_java
        end
      end

      class URI
        include FeatureSetter

        def call(value)
          value.to_s
        end
      end

      class Path
        include FeatureSetter

        def call(value)
          case value
          when Pathname
            ::URI::File.build({:path => ::URI::RFC2396_PARSER.escape(value.to_path)}).to_s
          when File, Dir
            ::URI::File.build({:path => ::URI::RFC2396_PARSER.escape(value.to_path)}).to_s
          else
            value.to_s
          end
        end
      end
    end
  end
end
