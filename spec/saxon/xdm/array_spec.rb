require 'saxon/xdm'
require_relative 'sequence_like_examples'

module Saxon
  RSpec.describe XDM::Array do
    context "creation" do
      context "from Ruby Arrays" do
        specify "an array of simple values gets correctly created" do
          expect(described_class.create([1,2]).to_a).to eq([XDM.AtomicValue(1), XDM.AtomicValue(2)])
        end

        specify "an array containing "
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
    end
  end
end
