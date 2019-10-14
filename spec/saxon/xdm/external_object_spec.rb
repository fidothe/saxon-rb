require 'saxon/xdm'
require_relative 'sequence_like_examples'

module Saxon
  RSpec.describe XDM::ExternalObject do
    let(:s9_xdm_external_object) { S9API::XdmExternalObject.new(1) }
    subject { described_class.new(s9_xdm_external_object) }

    context "instances" do
      it_should_behave_like "an XDM Value hierarchy sequence-like"
      it_should_behave_like "an XDM Item hierarchy sequence-like"
    end
  end
end
