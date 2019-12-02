require 'saxon/xdm'
require 'saxon/processor'
require_relative 'sequence_like_examples'
require 'set'

module Saxon
  RSpec.describe XDM::Value do
    let(:processor) { Saxon::Processor.create }

    describe "being created" do
      let(:node) { fixture_doc(processor, 'eg.xml') }
      let(:atomic_value) { XDM.AtomicValue(1) }

      context "when being passed an existing net.sf.saxon.s9api.XdmValue" do
        specify "creates an XDM::Value when given a multi-item XdmValue" do
          s9_value = described_class.create([1,2]).to_java
          value = described_class.create(s9_value)

          expect(value.to_java).to be(s9_value)
        end

        specify "creates an XDM::AtomicValue for the sole item when given a single-item XdmValue containing an XdmAtomicValue" do
          s9_value = S9API::XdmValue.new([atomic_value.to_java])
          value = described_class.create(s9_value)

          expect(value).to eq(atomic_value)
        end

        specify "returns an XDM::EmptySequence instance when the XdmValue is empty" do
          s9_value = S9API::XdmValue.new([])
          value = described_class.create(s9_value)

          expect(value).to be(XDM.EmptySequence())
        end

        specify "returns an XDM::EmptySequence instance when handed XdmEmptySequence()" do
          s9_value = S9API::XdmEmptySequence.getInstance()
          value = described_class.create(s9_value)

          expect(value).to be(XDM.EmptySequence())
        end
      end

      specify "handles being passed an existing XDM::Value correctly" do
        value = described_class.create([1,2])

        expect(described_class.create(value)).to be(value)
      end

      context "when handed a multi-item array" do
        it "from an array of XDM Items" do
          o1 = XDM.AtomicValue(1)
          o2 = XDM.AtomicValue(2)

          value = XDM::Value.create([o1, o2])

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(2)
        end

        it "from an array of regular ruby objects" do
          value = XDM::Value.create([1, 2])

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(2)
          expect(value.first).to eq(XDM::AtomicValue.create(1))
        end
      end

      context "when handed a single-item array" do
        specify "an XDM::Node returns itself" do
          value = XDM::Value.create([node])
          expect(value).to be_a(XDM::Node)
        end

        specify "an XDM::AtomicValue returns itself" do
          value = XDM::Value.create([atomic_value])
          expect(value).to be_a(XDM::AtomicValue)
        end

        specify "an XDM::Value returns a new itself" do
          value = XDM::Value.create([atomic_value, node])

          expect(XDM::Value.create([value])).to eq(value)
        end

        specify "a plain Ruby value returns an XDM::AtomicValue" do
          value = XDM::Value.create([1])

          expect(value).to eq(atomic_value)
        end
      end

      context "when handed a single item" do
        specify "an XDM::Value is returned unchanged" do
          value = XDM::Value.create([atomic_value, node])

          expect(XDM::Value.create(value)).to eq(value)
        end

        specify "a plain Ruby value returns an XDM::AtomicValue" do
          value = XDM::Value.create(1)

          expect(value).to eq(atomic_value)
        end
      end

      context "when handed multiple items" do
        specify "returns a new XDM::Value" do
          value = XDM::Value.create(atomic_value, node)

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(2)
        end

        specify "if one of the items is an XDM::Value it is unwrapped correctly into the new sequence" do
          other_value = XDM::Value.create(atomic_value, node)

          value = XDM::Value.create('a', other_value, 'b')

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(4)
          expect(value.to_a).to eq([XDM.AtomicValue('a'), atomic_value, node, XDM.AtomicValue('b')])
        end

        specify "if one of the items is a Ruby array it is unwrapped correctly into the new sequence" do
          value = XDM::Value.create('a', [atomic_value, node], 'b')

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(4)
          expect(value.to_a).to eq([XDM.AtomicValue('a'), atomic_value, node, XDM.AtomicValue('b')])
        end

        specify "if one of the items is a non-Array Ruby Enumerable it is unwrapped correctly into the new sequence" do
          value = XDM::Value.create('a', [atomic_value, node].to_enum, Set.new([4, 5]), 'b')

          expect(value).to be_a(XDM::Value)
          expect(value.size).to eq(6)
          expect(value.to_a).to eq([XDM.AtomicValue('a'), atomic_value, node, XDM.AtomicValue(4), XDM.AtomicValue(5), XDM.AtomicValue('b')])
        end
      end

      specify "returns EmptySequence if given empty input" do
        expect(XDM::Value.create([])).to be(XDM.EmptySequence())
      end
    end

    describe "instances" do
      let(:items) { [1,2,3].map { |v| XDM::AtomicValue.create(v) } }
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
        let(:node) { fixture_doc(processor, 'eg.xml') }
        let(:atomic_value) { XDM::AtomicValue.create(1) }

        subject { described_class.create([node, atomic_value]) }

        specify "returns xdm nodes" do
          expect(subject.to_a[0]).to be_a(Saxon::XDM::Node)
        end

        specify "returns xdm atomic value" do
          expect(subject.to_a[1]).to be_a(Saxon::XDM::AtomicValue)
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

      it_should_behave_like "an XDM Value hierarchy sequence-like"
    end
  end
end
