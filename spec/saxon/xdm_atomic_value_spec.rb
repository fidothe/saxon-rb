require 'saxon/xdm_atomic_value'
require 'saxon/qname'
require 'saxon/item_type'

RSpec.describe Saxon::XdmAtomicValue do
  describe "creating from Ruby objects" do
    context "using primitives" do
      specify "a Ruby String produces an xs:string" do
        value = described_class.create('a')

        expect(value.type_name).to eq(Saxon::ItemType.get_type(::String).type_name)
      end

      specify "a Ruby Integer produces an xs:integer" do
        value = described_class.create(1)

        expect(value.type_name).to eq(Saxon::ItemType.get_type('xs:integer').type_name)
      end
    end

    context "specifying value type" do
      specify "an explicit ItemType can be used to produce a specific typed value" do
        item_type = Saxon::ItemType.get_type('xs:positiveInteger')
        value = described_class.create(1, item_type)

        expect(value.type_name).to eq(item_type.type_name)
      end

      specify "an xs:X type name can be used to produce a specific typed value" do
        item_type = Saxon::ItemType.get_type('xs:negativeInteger')
        value = described_class.create(-1, 'xs:negativeInteger')

        expect(value.type_name).to eq(item_type.type_name)
      end
    end

    context "using lexical form with specified type" do
      specify "a string can be used to produce an xs:Date" do
        item_type = Saxon::ItemType.get_type('xs:date')
        value = described_class.create('2019-09-25', item_type)

        expect(value.type_name).to eq(item_type.type_name)
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
  end
end
