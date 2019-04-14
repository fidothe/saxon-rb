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

      xspecify "a Ruby Fixnum produces an xs:integer" do
        value = described_class.create(1)

        # TODO: xs:long is kinda correct, but we probably want the more
        # abstract xs:integer, which means a unification of the logic here and
        # in Saxon::ItemType is needed
        expect(value.type_name).to eq(Saxon::ItemType.get_type('xs:long').type_name)
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

      specify "have the same hash as another instance representing the same node" do
        expect(subject.hash).to eq(n2.hash)
      end
    end
  end
end
