require 'saxon/processor'
require 'saxon/source'
require 'saxon/xslt/compiler'

RSpec.describe Saxon::XSLT::Compiler do
  let(:processor) { Saxon::Processor.create }

  it "is instantiated from a Processor factory method" do
    expect(processor.xslt_compiler).to be_a(Saxon::XSLT::Compiler)
  end

  describe "producing a compiler" do
    context "without data in the static context" do
      it "can be produced simply from a Saxon::Processor" do
        expect(Saxon::XSLT::Compiler.create(processor)).to be_a(Saxon::XSLT::Compiler)
      end
    end
  end
end
