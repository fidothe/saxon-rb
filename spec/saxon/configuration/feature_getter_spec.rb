require 'saxon/configuration/feature_getter'
require 'uri'
require 'pathname'

class Saxon::Configuration
  RSpec.describe FeatureGetter do
    describe FeatureGetter::Boolean do
      subject { described_class.new }

      specify "passes its value through" do
        expect(subject.call(true)).to be(true)
        expect(subject.call(false)).to be(false)
      end
    end

    describe FeatureGetter::Generic do
      subject { described_class.new }

      specify "calls to_s on the value" do
        expect(subject.call("string")).to eq("string")
        expect(subject.call(1)).to eq("1")
      end
    end

    describe FeatureGetter::URI do
      subject { described_class.new }
      let(:eg_uri_string) { "http://example.org/feature" }
      let(:eg_uri) { URI(eg_uri_string) }

      specify "returns the URI for a URI string" do
        expect(subject.call(eg_uri_string)).to eq(eg_uri)
      end
    end
  end
end
