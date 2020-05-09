require 'saxon/version/library'
require 'saxon/feature_flags'

module Saxon
  RSpec.describe FeatureFlags::Version do
    describe "methods only exposed in certain versions" do
      def test_class(target_version)
        Class.new {
          extend Saxon::FeatureFlags::Helpers

          def test_method
            :result
          end
          requires_saxon_version :test_method, "> #{target_version}"
        }
      end

      specify "raises UnavailableInThisSaxonVersionError if it's called" do
        klass = test_class(Saxon::Version::Library.loaded_version)

        expect { klass.new.test_method }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
      end

      specify "executes normally if the version is okay" do
        klass = test_class(Saxon::Version::Library.loaded_version.components[0] - 1)

        expect(klass.new.test_method).to eq(:result)
      end

      context "rebound method caching" do
        specify "works for passing checks" do
          klass = test_class(Saxon::Version::Library.loaded_version.components[0] - 1)

          instance = klass.new
          expect(klass.new.test_method).to eq(:result)
          expect(instance.test_method).to eq(:result)
          expect(instance.test_method).to eq(:result)
        end

        specify "works for failing checks" do
          klass = test_class(Saxon::Version::Library.loaded_version)

          instance = klass.new
          expect { klass.new.test_method }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
          expect { instance.test_method }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
          expect { instance.test_method }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
        end
      end
    end

    describe "classes only defined in certain versions"
  end
end