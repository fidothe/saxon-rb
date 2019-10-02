require 'saxon/xdm_atomic_value'
require 'saxon/qname'
require 'saxon/item_type'

module Saxon
  RSpec.describe XdmAtomicValue do
    describe "creating from Ruby objects" do
      context "using primitives" do
        specify "a Ruby String produces an xs:string" do
          value = described_class.create('a')

          expect(value.type_name).to eq(ItemType.get_type(::String).type_name)
        end

        specify "a Ruby Integer produces an xs:integer" do
          value = described_class.create(1)

          expect(value.type_name).to eq(ItemType.get_type('xs:integer').type_name)
        end
      end

      context "specifying value type" do
        specify "an explicit ItemType can be used to produce a specific typed value" do
          item_type = ItemType.get_type('xs:positiveInteger')
          value = described_class.create(1, item_type)

          expect(value.type_name).to eq(item_type.type_name)
        end

        specify "an xs:X type name can be used to produce a specific typed value" do
          item_type = ItemType.get_type('xs:negativeInteger')
          value = described_class.create(-1, 'xs:negativeInteger')

          expect(value.type_name).to eq(item_type.type_name)
        end
      end

      context "using implied lexical form with specified type" do
        specify "a string can be used to produce an xs:Date" do
          item_type = ItemType.get_type('xs:date')
          value = described_class.create('2019-09-25', item_type)

          expect(value.type_name).to eq(item_type.type_name)
        end

        specify "the string 'false' produces an xs:boolean value of true" do
          item_type = ItemType.get_type('xs:boolean')
          value = described_class.create('false', item_type)

          expect(value.type_name).to eq(item_type.type_name)
          expect(value.to_ruby).to be(true)
        end
      end

      context "using explicit lexical form with specified type" do
        specify "the string 'false' produces an xs:boolean value of false" do
          item_type = ItemType.get_type('xs:boolean')
          value = described_class.from_lexical_string('false', item_type)

          expect(value.type_name).to eq(item_type.type_name)
          expect(value.to_ruby).to be(false)
        end
      end

      context "Namespace-sensitive XDM Atomic Values containing" do
        context "QNames" do
          let(:qname) { QName.create(prefix: 'a', uri: 'http://example.org/#ns', local_name: 'name') }
          let(:qname_type) { ItemType.get_type('xs:QName') }

          specify "can be created by passing a Saxon::QName" do
            value = described_class.create(qname)

            expect(value.type_name).to eq(qname_type.type_name)
            expect(value.to_ruby).to eq(qname)
          end

          specify "can be created by passing a Saxon Java QName" do
            value = described_class.create(qname.to_java)

            expect(value.type_name).to eq(qname_type.type_name)
            expect(value.to_ruby).to eq(qname)
          end

          specify "does not allow creation via string/explicit type name" do
            expect {
              described_class.create('name', 'xs:QName')
            }.to raise_error(ItemType::LexicalStringConversion::Errors::UnconvertableNamespaceSensitveItemType)
          end

          specify "explicit lexical form creation is prevented in the class" do
            expect {
              described_class.from_lexical_string('name', 'xs:QName')
            }.to raise_error(XdmAtomicValue::CannotCreateQNameFromString)
          end
        end

        context "xs:NOTATION" do
          let(:qname) { QName.create(prefix: 'a', uri: 'http://example.org/#ns', local_name: 'name') }
          let(:notation_type) { ItemType.get_type('xs:NOTATION') }

          specify "cannot be created by passing a Saxon::QName and explicit type" do
            expect {
              described_class.create(qname, 'xs:NOTATION')
            }.to raise_error(XdmAtomicValue::NotationCannotBeDirectlyCreated)
          end

          specify "does not allow creation via string/explicit type name" do
            expect {
              described_class.create('name', 'xs:NOTATION')
            }.to raise_error(XdmAtomicValue::NotationCannotBeDirectlyCreated)
          end
        end
      end
    end

    describe "instances" do
      subject { described_class.create('a') }

      specify "return the underlying Java XdmAtomicValue" do
        expect(subject.to_java).to be_a(Saxon::S9API::XdmAtomicValue)
      end

      specify "return the QName describing their Item type" do
        expect(subject.type_name.to_s).to eq('xs:string')
      end

      context "when compared, atomic values" do
        let(:n2) { described_class.create('a') }

        specify "are #== equal to another instance representing the same node" do
          expect(subject == n2).to be(true)
        end

        specify "are #eql? equal to another instance representing the same node" do
          expect(subject.eql?(n2)).to be(true)
        end

        specify "have the same hash as another instance representing the same underlying Java object" do
          expect(subject.hash).to eq(n2.hash)
        end
      end

      context "returning native-Ruby values" do
        specify "XDM types with a sensible Ruby equivalent return their value as an instance of that class" do
          value = described_class.create('1', 'xs:integer')

          expect(value.to_ruby).to eq(1)
          expect(value.to_ruby.class).to be(::Integer)
        end

        specify "XDM types with no sensible Ruby equivalent return their lexical string representation" do
          value = described_class.create('PT1H', 'xs:duration')

          expect(value.to_ruby).to eq('PT1H')
          expect(value.to_ruby.class).to be(::String)
        end

        specify "the original XML string value can still be obtained if needed" do
          value = described_class.create(1)

          expect(value.to_s).to eq('1')
        end
      end
    end
  end
end