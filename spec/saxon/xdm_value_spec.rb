require 'saxon/xdm_value'
require 'saxon/processor'
require 'saxon/xdm_atomic_value'

module Saxon
  RSpec.describe XdmValue do
    describe "being created" do
      it "allows the creation of XDM Values from an array of XDM Items" do
        o1 = XdmAtomicValue.new(1)
        o2 = XdmAtomicValue.new(2)

        value = XdmValue.create([o1, o2])
        expect(value).to be_a(XdmValue)
        expect(value.size).to eq(2)
      end
    end

    describe "instances" do
      let(:items) { [1,2,3].map { |v| XdmAtomicValue.create(v) } }
      subject { described_class.create(items) }

      it "returns the underlying Java XdmValue" do
        expect(subject.to_java).to be_a(Saxon::S9API::XdmValue)
      end

      it "can report the size of the sequence" do
        expect(subject.size).to eq(3)
      end

      context "iteration" do
        it "behaves as an Enumerable, yielding Xdm Items" do
          expect(subject.each.to_a).to eq(items)
        end
      end

      context "wrapping member items appropriately" do
        let(:processor) { Saxon::Processor.create }
        let(:node) { fixture_doc(processor, 'eg.xml') }
        let(:atomic_value) { XdmAtomicValue.create(1) }

        subject { described_class.create([node, atomic_value]) }

        specify "returns xdm nodes" do
          expect(subject.to_a[0]).to be_a(Saxon::XdmNode)
        end

        specify "returns xdm atomic value" do
          expect(subject.to_a[1]).to be_a(Saxon::XdmAtomicValue)
        end
      end

      context "when compared, values representing the same sequence of items" do
        let(:v2) { described_class.create(items) }

        specify "are #== equal" do
          expect(subject == v2).to be(true)
        end

        specify "are #eql? equal" do
          expect(subject.eql?(v2)).to be(true)
        end

        specify "have the same hash" do
          expect(subject.hash).to eq(v2.hash)
        end
      end
    end
  end
end
