require 'saxon/processor'
require 'saxon/xpath/compiler'

RSpec.describe Saxon::XPath::Compiler do
  let(:processor) { Saxon::Processor.create }

  it "is instantiated from a Processor factory method" do
    expect(processor.xpath_compiler).to be_a(Saxon::XPath::Compiler)
  end

  describe "compiling an XPath" do
    subject { processor.xpath_compiler }

    specify "a simple XPath" do
      expect(subject.compile('/element')).to be_a(Saxon::XPath::Executable)
    end
  end
end
