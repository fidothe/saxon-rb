require 'saxon/xdm'
require_relative 'sequence_like_examples'

module Saxon
  RSpec.describe XDM::Array do
    context "creation" do
      context "from Ruby Arrays" do
        specify "an array of simple values gets correctly created" do
          expect(described_class.create([1,2]).to_a).to eq([XDM.AtomicValue(1), XDM.AtomicValue(2)])
        end

        specify "an array containing nested arrays becomes an XDM Array of XDM Values" do
          expect(described_class.create([[1,2], [3,4]]).to_a).to eq([
            XDM.Value([1,2]),
            XDM.Value([3,4])
          ])
        end
      end
    end

    context "instances" do
      let(:s9_xdm_atomic_value) { S9API::XdmAtomicValue.new(1) }
      let(:s9_xdm_array) { S9API::XdmArray.new([s9_xdm_atomic_value]) }
      subject { XDM::Array.new(s9_xdm_array) }

      it_should_behave_like "an XDM Value hierarchy sequence-like"
      it_should_behave_like "an XDM Item hierarchy sequence-like"

      specify "acts as an Enumerable" do
        expect(subject.each.to_a).to eq([XDM.AtomicValue(s9_xdm_atomic_value)])
      end

      specify "returns the size of the array" do
        expect(subject.length).to eq(1)
        expect(subject.size).to eq(1)
      end

      specify "elements can be accessed using []" do
        expect(subject[0]).to eq(XDM.AtomicValue(1))
      end

      context "when compared, XDM Arrays" do
        let(:a2) { described_class.create([XDM.AtomicValue(S9API::XdmAtomicValue.new(1))]) }

        specify "are #== equal to another instance representing the same array of values" do
          expect(subject == a2).to be(true)
        end

        specify "are #eql? equal to another instance representing the same array of values" do
          expect(subject.eql?(a2)).to be(true)
        end

        specify "have the same hash as another instance representing the same array of values" do
          expect(subject.hash).to eq(a2.hash)
        end
      end

      context "immutability" do
        specify "the Ruby array we use to hold the wrapped array cannot be altered" do
          expect { subject.to_a.append(1) }.to raise_error(FrozenError)
        end
      end
    end
  end
end
