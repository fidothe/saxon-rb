require 'saxon/item_type'
require 'saxon/processor'
require 'saxon/qname'

module Saxon
  RSpec.describe ItemType do
    context "mapping Ruby types to xs:* types" do
      {
        ::String => S9API::ItemType::STRING,
        ::Array => S9API::ItemType::ANY_ARRAY
      }.each do |ruby_type, xsd_type|
        specify "Ruby type #{ruby_type} maps to #{xsd_type}" do
          expect(described_class.get_type(ruby_type).to_java).to be(xsd_type)
        end
      end

      specify "unmapped types raise an appropriate error" do
        expect {
          described_class.get_type(::Object)
        }.to raise_error(Saxon::ItemType::UnmappedRubyTypeError)
      end
    end

    context "mapping string QNames using the xs: namespace" do
      {
        'xs:string' => S9API::ItemType::STRING,
        'xs:duration' => S9API::ItemType::DURATION
      }.each do |qname_str, xsd_type|
        specify "Ruby string '#{qname_str}' maps to #{xsd_type}" do
          expect(described_class.get_type(qname_str).to_java).to be(xsd_type)
        end
      end

      specify "unmapped type strings raise an appropriate error" do
        expect {
          described_class.get_type('xs:fnord')
        }.to raise_error(Saxon::ItemType::UnmappedXSDTypeNameError)
      end
    end

    context "instances" do
      subject { described_class.get_type(::String) }

      specify "return their type_name as a Saxon::QName" do
        expect(subject.type_name).to be_a(Saxon::QName)
      end

      specify "return their underlying Java object on request" do
        expect(subject.to_java).to be(S9API::ItemType::STRING)
      end

      context "instances referring to the same underlying type" do
        let(:other_instance) { described_class.new(S9API::ItemType::STRING) }

        specify "compare equal" do
          expect(subject).to eq(other_instance)
        end

        specify "generate the same code for #hash" do
          expect(subject.hash).to eq(other_instance.hash)
        end
      end
    end
  end

  RSpec.describe ItemType::Factory do
    let(:processor) { Saxon::Processor.create }

    describe "instantiating" do
      it "requires a Processor" do
        decl = described_class.new(processor)
        expect(decl).to be_a(Saxon::ItemType::Factory)
      end
    end
  end
end
