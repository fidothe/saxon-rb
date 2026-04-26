require 'saxon/configuration/feature_validator'
require 'uri'
require 'pathname'

class Saxon::Configuration
  class FixtureCalendar < Java::JavaUtil::Calendar; end

  RSpec.describe FeatureValidator do
    describe FeatureValidator::Boolean do
      subject { described_class.new }

      specify "accepts any value as valid" do
        expect(subject.valid?(true)).to be(true)
        expect(subject.valid?(false)).to be(true)
        expect(subject.valid?(nil)).to be(true)
        expect(subject.valid?(1)).to be(true)
        expect(subject.valid?("string")).to be(true)
      end
    end

    describe FeatureValidator::SimpleString do
      subject { described_class.new }

      specify "accepts any value that responds to to_s as valid" do
        expect(subject.valid?("string")).to be(true)
        expect(subject.valid?(1)).to be(true)
        expect(subject.valid?(nil)).to be(true)
      end

      specify "accepts a Java string" do
        java_string = "java string".to_java
        expect(subject.valid?(java_string)).to be(true)
      end
    end

    describe FeatureValidator::CommaSeparatedIntegers do
      subject { described_class.new }

      specify "a string containing comma-separated integers is valid" do
        expect(subject.valid?("1,2")).to be(true)
      end

      specify "a string with a single integer is invalid" do
        expect(subject.valid?("1")).to be(false)
      end

      specify "a string with non-integer values is invalid" do
        expect(subject.valid?("a,b")).to be(false)
      end
    end

    describe FeatureValidator::NamedIntegers do
      subject {
        described_class.new(->() {
          {STRIP: 1, LAX: 2}
        })
      }

      specify "a symbol corresponding to a named integer is valid" do
        expect(subject.valid?(:STRIP)).to be(true)
      end

      specify "an integer corresponding to a named integer is valid" do
        expect(subject.valid?(1)).to be(true)
      end

      specify "a symbol that does not correspond to a named integer is invalid" do
        expect(subject.valid?(:INVALID)).to be(false)
      end

      specify "an integer that does not correspond to a named integer is invalid" do
        expect(subject.valid?(3)).to be(false)
      end
    end

    describe FeatureValidator::StringSet do
      subject { described_class.new(['value1', 'value2']) }

      specify "reports a value from the list as valid" do
        expect(subject.valid?('value1')).to be(true)
      end

      specify "reports a value not in the list as invalid" do
        expect(subject.valid?('invalid')).to be(false)
      end
    end

    describe FeatureValidator::IntegerSet do
      subject { described_class.new([10, 20]) }

      specify "reports a value from the list as valid" do
        expect(subject.valid?(10)).to be(true)
      end

      specify "reports a value not in the list as invalid" do
        expect(subject.valid?(30)).to be(false)
      end
    end

    describe FeatureValidator::Flags do
      subject { described_class.new('abcde', '0') }

      specify "accepts any value that will to_s to a valid flag" do
        expect(subject.valid?("a")).to be(true)
        expect(subject.valid?(0)).to be(true)
      end

      specify "reports a value that will to_s to an invalid flag as invalid" do
        expect(subject.valid?("x")).to be(false)
        expect(subject.valid?(1)).to be(false)
      end

      specify "accepts any value that will to_s to a list of valid flags" do
        expect(subject.valid?("abc")).to be(true)
      end

      specify "a string that includes flags and the no-flags indicator is invalid" do
        expect(subject.valid?("a0")).to be(false)
      end
    end

    describe FeatureValidator::ClassValidator do
      class FixtureCalendar < Java::JavaUtil::Calendar; end

      subject { described_class.new(->() { Java::JavaUtil::Calendar.java_class }) }

      specify "reports a Ruby instance of a subclass is valid" do
        expect(subject.valid?(FixtureCalendar.new)).to be(true)
      end

      specify "reports a Java instance of a subclass is valid" do
        expect(subject.valid?(FixtureCalendar.new.to_java)).to be(true)
      end

      specify "reports an instance of an unrelated class as invalid" do
        expect(subject.valid?(1)).to be(false)
      end
    end

    describe FeatureValidator::ClassName do
      subject { described_class.new(->() { Java::JavaUtil::Calendar }) }

      specify "reports the name of a subclass as valid" do
        expect(subject.valid?('::Saxon::Configuration::FixtureCalendar')).to be(true)
      end

      specify "reports the name of a subclass (as a java package-plus-class name) as valid" do
        expect(subject.valid?('java.util.Calendar')).to be(true)
      end

      specify "reports the name of a non-existent class in a java package as invalid" do
        expect(subject.valid?('java.util.NonExistentClass')).to be(false)
      end

      specify "reports the name of a class in anon-existent java package as invalid" do
        expect(subject.valid?('java.nonexistence.Calendar')).to be(false)
      end

      specify "reports the name of an unrelated class as invalid" do
        expect(subject.valid?('::String')).to be(false)
      end
    end

    describe FeatureValidator::SimpleInteger do
      subject { described_class.new }

      specify "an Integer value is valid" do
        expect(subject.valid?(1)).to be(true)
      end

      specify "a non-Integer value like a String is invalid" do
        expect(subject.valid?("string")).to be(false)
      end

      specify "accepts a Java integer" do
        java_integer = 1.to_java(:int)
        expect(subject.valid?(java_integer)).to be(true)
      end
    end

    describe FeatureValidator::URI do
      subject { described_class.new }
      let(:eg_uri_string) { "http://example.org/feature" }
      let(:eg_uri) { URI(eg_uri_string) }

      specify "a URI is valid" do
        expect(subject.valid?(eg_uri)).to be(true)
      end

      specify "a URI string is valid" do
        expect(subject.valid?(eg_uri_string)).to be(true)
      end

      specify "a non-URI string is invalid" do
        expect(subject.valid?("string")).to be(false)
      end
    end

    describe FeatureValidator::Path do
      subject { described_class.new }
      let(:eg_path_string) { "/path/to/fs/object" }
      let(:eg_path) { Pathname(eg_path_string) }
      let(:eg_file) { File.new(__FILE__) }
      let(:eg_dir) { Dir.new(__dir__) }

      specify "a Pathname is valid" do
        expect(subject.valid?(eg_path)).to be(true)
      end

      specify "a File is valid" do
        expect(subject.valid?(eg_file)).to be(true)
      end

      specify "a Directory is valid" do
        expect(subject.valid?(eg_dir)).to be(true)
      end

      specify "a relative-path string is valid" do
        expect(subject.valid?("relative")).to be(true)
      end

      specify "an absolute path string is valid" do
        expect(subject.valid?(eg_path_string)).to be(true)
      end

      specify "an absolute file URI is valid" do
        expect(subject.valid?("file:#{eg_path_string}")).to be(true)
      end

      specify "a string that will not convert to a valid path is invalid" do
        expect(subject.valid?("string\0")).to be(false)
      end

      specify "an integer is invalid" do
        expect(subject.valid?(1)).to be(false)
      end
    end

    describe FeatureValidator::ItemType do
      subject { described_class.new }
      let(:item_type_string) { "xs:string" }
      let(:item_type) { Saxon::ItemType.get_type(item_type_string) }

      specify "an ItemType is valid" do
        expect(subject.valid?(item_type)).to be(true)
      end

      specify "a string parseable as a base XSD type is valid" do
        expect(subject.valid?(item_type_string)).to be(true)
      end

      specify "a string parseable as an XPath node test is valid" do
        expect(subject.valid?("element()")).to be(true)
      end

      specify "a string not parseable as an ItemType is invalid" do
        expect(subject.valid?("non:sense")).to be(false)
      end
    end
  end
end
