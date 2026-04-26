require 'saxon/configuration/feature_setter'
require 'uri'
require 'pathname'

class Saxon::Configuration
  class FixtureCalendar < Java::JavaUtil::Calendar; end

  RSpec.describe FeatureSetter do
    describe FeatureSetter::Boolean do
      subject { described_class.new }

      specify "converts a truthy value to true" do
        expect(subject.call(true)).to be(true)
        expect(subject.call(1)).to be(true)
        expect(subject.call("string")).to be(true)
      end

      specify "converts a falsy value to false" do
        expect(subject.call(false)).to be(false)
        expect(subject.call(nil)).to be(false)
      end
    end

    describe FeatureSetter::Generic do
      subject { described_class.new }

      specify "calls to_s on the value" do
        expect(subject.call("string")).to eq("string")
        expect(subject.call(1)).to eq("1")
      end
    end

    describe FeatureSetter::Klass do
      subject { described_class.new }

      specify "returns the java representation of the value" do
        expect(subject.call("")).to be_a(Java::JavaLang::String)
      end
    end

    describe FeatureSetter::URI do
      subject { described_class.new }
      let(:eg_uri_string) { "http://example.org/feature" }
      let(:eg_uri) { URI(eg_uri_string) }

      specify "returns the URI string for a URI" do
        expect(subject.call(eg_uri)).to eq("http://example.org/feature")
      end

      specify "passes through a string" do
      end
    end

    describe FeatureSetter::Path do
      subject { described_class.new }
      let(:eg_path_string) { "/path/to/fs/object" }
      let(:eg_path) { Pathname(eg_path_string) }
      let(:eg_file) { File.new(__FILE__) }
      let(:eg_dir) { Dir.new(__dir__) }

      def file_uri(file_or_dir)
        "file://#{URI::RFC2396_PARSER.escape(file_or_dir.to_path)}"
      end

      specify "returns a file: uri string" do
        expect(subject.call(eg_path)).to eq("file:///path/to/fs/object")
        expect(subject.call(eg_file)).to eq(file_uri(eg_file))
        expect(subject.call(eg_dir)).to eq(file_uri(eg_dir))
      end
    end
  end
end
