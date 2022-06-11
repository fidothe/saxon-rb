require 'saxon/version/library'
require 'saxon/feature_flags'

module Saxon
  RSpec.describe FeatureFlags::Version do
    describe "methods only exposed in certain versions, and which are no-ops if used" do
      def test_class(target_version)
        Class.new {
          extend Saxon::FeatureFlags::Helpers

          def test_method
            :result
          end
          requires_saxon_version_or_noop :test_method, "> #{target_version}"
        }
      end

      specify "returns nil if it's called" do
        klass = test_class(Saxon::Version::Library.loaded_version)

        expect(klass.new.test_method).to be(nil)
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
          expect(klass.new.test_method).to be(nil)
          expect(instance.test_method).to be(nil)
          expect(instance.test_method).to be(nil)
        end
      end
    end

    describe "methods only exposed in certain versions, and which explode if used" do
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

    describe "a mix of explodey and no-op method constraints" do
      def test_class(target_version)
        original_methods = {}
        klass = Class.new {
          extend Saxon::FeatureFlags::Helpers

          def m1
            :result
          end
          requires_saxon_version :m1, "> #{target_version}"

          def m2
            :result
          end
          original_methods[:m2] = instance_method(:m2)
          requires_saxon_version :m2, "> #{target_version}"

          def m3
            :result
          end
          requires_saxon_version_or_noop :m3, "> #{target_version}"

          def m4
            :result
          end
          original_methods[:m4] = instance_method(:m4)
          requires_saxon_version_or_noop :m4, "> #{target_version}"
        }
        [klass, original_methods]
      end

      context "with a failing version check" do
        let(:version) { Saxon::Version::Library.loaded_version }

        specify "accessing one should-be explodey method resolves all methods, including no-ops" do
          klass, original_methods = test_class(version)
          potential_m2 = klass.instance_method(:m2)
          potential_m4 = klass.instance_method(:m4)
          instance = klass.new

          begin
            instance.m1
          rescue Saxon::FeatureFlags::UnavailableInThisSaxonVersionError
          end

          expect(klass.instance_method(:m2)).to_not eq(potential_m2)
          expect(klass.instance_method(:m2)).to_not eq(original_methods[:m2])
          expect(klass.instance_method(:m4)).to_not eq(potential_m4)
          expect(klass.instance_method(:m4)).to_not eq(original_methods[:m4])
        end

        specify "accessing one should-be no-op method resolves all methods, including explodeys" do
          klass, original_methods = test_class(version)
          potential_m2 = klass.instance_method(:m2)
          potential_m4 = klass.instance_method(:m4)
          instance = klass.new

          instance.m3

          expect(klass.instance_method(:m2)).to_not eq(potential_m2)
          expect(klass.instance_method(:m2)).to_not eq(original_methods[:m2])
          expect(klass.instance_method(:m4)).to_not eq(potential_m4)
          expect(klass.instance_method(:m4)).to_not eq(original_methods[:m4])
        end
      end

      context "with a successful version check" do
        let(:version) { Saxon::Version::Library.loaded_version.components[0] - 1 }

        specify "accessing one should-be explodey method resolves all methods, including no-ops" do
          klass, original_methods = test_class(version)
          instance = klass.new

          instance.m1

          expect(klass.instance_method(:m2)).to eq(original_methods[:m2])
          expect(klass.instance_method(:m4)).to eq(original_methods[:m4])
        end

        specify "accessing one should-be no-op method resolves all methods, including explodeys" do
          klass, original_methods = test_class(version)
          instance = klass.new

          instance.m3

          expect(klass.instance_method(:m2)).to eq(original_methods[:m2])
          expect(klass.instance_method(:m4)).to eq(original_methods[:m4])
        end
      end
    end

    describe "a mix of version constraints" do
      def test_class(target_version)
        original_methods = {}
        klass = Class.new {
          extend Saxon::FeatureFlags::Helpers

          def m1
            :result
          end
          original_methods[:m1] = instance_method(:m1)
          requires_saxon_version :m1, "> #{target_version}"

          def m2
            :result
          end
          original_methods[:m2] = instance_method(:m2)
          requires_saxon_version :m2, ">= #{target_version}"

          def m3
            :result
          end
          original_methods[:m3] = instance_method(:m3)
          requires_saxon_version_or_noop :m3, "> #{target_version}"

          def m4
            :result
          end
          original_methods[:m4] = instance_method(:m4)
          requires_saxon_version_or_noop :m4, ">= #{target_version}"
        }
        [klass, original_methods]
      end

      let(:version) { Saxon::Version::Library.loaded_version }

      specify "accessing one method resolves all methods, whatever the version constraint" do
        klass, original_methods = test_class(version)
        instance = klass.new

        begin
          instance.m1
        rescue Saxon::FeatureFlags::UnavailableInThisSaxonVersionError
        end

        expect(klass.instance_method(:m1)).to_not eq(original_methods[:m1])
        expect(klass.instance_method(:m2)).to eq(original_methods[:m2])
        expect(klass.instance_method(:m3)).to_not eq(original_methods[:m3])
        expect(klass.instance_method(:m4)).to eq(original_methods[:m4])
      end
    end

    describe "classes only defined in certain versions" do
      def test_mod(target_version)
        test_class = Class.new {
          def self.test_method
            :result
          end
        }
        Module.new do
          extend Saxon::FeatureFlags::Helpers

          const_set(:Test, test_class)
          class_requires_saxon_version(test_class, "> #{target_version}")
        end
      end

      specify "raises UnavailableInThisSaxonVersionError if it's instantiated" do
        mod = test_mod(Saxon::Version::Library.loaded_version)
        klass = mod::Test

        expect { klass.new }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
      end

      specify "raises UnavailableInThisSaxonVersionError if a class method is called" do
        mod = test_mod(Saxon::Version::Library.loaded_version)
        klass = mod::Test

        expect { klass.test_method }.to raise_error(Saxon::FeatureFlags::UnavailableInThisSaxonVersionError)
      end

      context "if the version check passes" do
        let(:klass) {
          mod = test_mod(Saxon::Version::Library.loaded_version.components[0] - 1)
          mod::Test
        }

        specify "instantiates normally" do
          expect(klass.new).to be_a(klass)
        end

        specify "executes class methods normally" do
          expect(klass.test_method).to eq(:result)
        end
      end
    end
  end
end