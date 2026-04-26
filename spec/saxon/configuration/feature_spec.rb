require 'saxon/configuration/feature'

class Saxon::Configuration
  RSpec.describe Feature do
    describe "enumerating the features" do
      specify "returns an expected instance" do
        features = described_class.all

        expect(features.find { |f| f.name == :allow_external_functions }).not_to be_nil
      end
    end

    describe "looking up a feature" do
      describe "by name" do
        specify "returns an expected instance" do
          feature = described_class.by_name(:allow_external_functions)

          expect(feature).not_to be_nil
          expect(feature.name).to eq(:allow_external_functions)
        end

        specify "returns nil for an unknown feature name" do
          expect(described_class.by_name(:rubbish)).to be_nil
        end
      end

      describe "by URI string" do
        specify "returns an expected instance" do
          feature = described_class.by_uri('http://saxon.sf.net/feature/allow-external-functions')

          expect(feature).not_to be_nil
          expect(feature.name).to eq(:allow_external_functions)
        end

        specify "returns nil for an unknown feature URI" do
          expect(described_class.by_uri('http://saxon.sf.net/feature/rubbish')).to be_nil
        end
      end

      describe "by URI" do
        specify "returns an expected instance" do
          feature = described_class.by_uri(URI('http://saxon.sf.net/feature/allow-external-functions'))

          expect(feature).not_to be_nil
          expect(feature.name).to eq(:allow_external_functions)
        end
      end

      specify "can use name" do
        feature = described_class.get(:allow_external_functions)

        expect(feature).not_to be_nil
        expect(feature.name).to eq(:allow_external_functions)
      end

      specify "can use URI" do
        feature = described_class.get(URI('http://saxon.sf.net/feature/allow-external-functions'))

        expect(feature).not_to be_nil
        expect(feature.name).to eq(:allow_external_functions)
      end

      specify "raises a NameError if the feature doesn't exist" do
        expect { described_class.get(:rubbish) }.to raise_error(NameError)
      end
    end

    describe "an instance" do
      subject { described_class.by_name(:allow_external_functions) }

      specify "has a name" do
        expect(subject.name).to eq(:allow_external_functions)
      end

      specify "has a URI" do
        expect(subject.uri).to eq('http://saxon.sf.net/feature/allow-external-functions')
      end

      specify "has a net.sf.saxon.lib.Feature" do
        expect(subject.s9feature).to be_a(Java::NetSfSaxonLib::Feature)
      end

      specify "has a setter data converter" do
        expect(subject.setter).to be_a(FeatureSetter)
      end

      specify "has a getter data converter" do
        expect(subject.getter).to be_a(FeatureGetter)
      end

      specify "has a value type validator" do
        expect(subject.validator).to be_a(FeatureValidator)
      end

      describe "setting the configuration property" do
        subject { described_class.by_name(:xpath_version_for_xslt) }
        let(:s9config) { instance_double(Saxon::S9API::Configuration) }

        specify "passes a correctly converted value and corresponding Saxon Feature to the configuration's set property method" do
          expect(s9config).to receive(:setConfigurationProperty).with(subject.s9feature, "30")

          subject.set(s9config, 30)
        end

        specify "rejects an invalid value" do
          expect(s9config).not_to receive(:setConfigurationProperty)

          expect { subject.set(s9config, "NaN") }.to raise_error(ArgumentError)
        end
      end

      describe "getting the configuration property" do
        subject { described_class.by_name(:xpath_version_for_xslt) }
        let(:s9config) { instance_double(Saxon::S9API::Configuration) }
        let(:getter) { double(subject.getter) }

        specify "gets the value corresponding to the Saxon Feature from the configuration and correctly converts it" do
          expect(s9config).to receive(:getConfigurationProperty).with(subject.s9feature).and_return(30)
          expect(subject.getter).to receive(:call).with(30).and_return("30")

          subject.get(s9config)
        end

        specify "rejects an invalid value" do
          expect(s9config).not_to receive(:setConfigurationProperty)

          expect { subject.set(s9config, "NaN") }.to raise_error(ArgumentError)
        end
      end
    end

    describe "features with class-based validation" do
      subject { described_class.by_name(:collation_uri_resolver) }

      let(:a_collation_resolver) { Java::net.sf.saxon.lib.StandardCollationURIResolver.new }

      specify "has a class validator" do
        expect(subject.validator).to be_a(FeatureValidator::ClassValidator)
      end

      specify "the class validator accepts valid classes" do
        expect(subject.validator.valid?(a_collation_resolver)).to be(true)
      end

      specify "the class validator rejects invalid classes" do
        expect(subject.validator.valid?(String)).to be(false)
      end
    end
  end
end
