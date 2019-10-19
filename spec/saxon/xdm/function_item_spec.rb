require 'saxon/processor'
require 'saxon/xdm'
require_relative 'sequence_like_examples'

module Saxon
  RSpec.describe XDM::FunctionItem do
    requires_pe do
      let(:processor) { Saxon::Processor.create }
      let(:s9_function_item) {
        Saxon::S9API::XdmFunctionItem.getSystemFunction(
          processor.to_java,
          Saxon::QName.clark('{http://www.w3.org/2005/xpath-functions}path').to_java,
          1
        )
      }
      subject { described_class.new(s9_function_item) }

      context "instances" do
        it_should_behave_like "an XDM Value hierarchy sequence-like"
        it_should_behave_like "an XDM Item hierarchy sequence-like"
      end
    end
  end
end
