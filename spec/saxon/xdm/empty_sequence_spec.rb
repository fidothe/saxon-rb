require 'saxon/xdm'
require_relative 'sequence_like_examples'

RSpec.describe Saxon::XDM::EmptySequence do
  describe "instances" do
    it "returns the underlying Java XdmEmptySequence" do
      expect(subject.to_java).to be_a(Saxon::S9API::XdmEmptySequence)
    end

    it "sequence_enum returns an empty enum" do
      expect(subject.sequence_enum.to_a).to eq([])
    end

    it "sequence_size returns 0" do
      expect(subject.sequence_size).to eq(0)
    end

    context "all instances compare equal" do
      let(:other) { described_class.new }

      specify "are #== equal to another instance representing the same node" do
        expect(subject == other).to be(true)
      end

      specify "are #eql? equal to another instance representing the same node" do
        expect(subject.eql?(other)).to be(true)
      end

      specify "have the same hash as another instance representing the same node" do
        expect(subject.hash).to eq(other.hash)
      end
    end

    it_should_behave_like "an XDM Value hierarchy sequence-like"
  end

  specify ".create returns a cached instance" do
    expect(described_class.create).to be(described_class.create)
  end
end
