require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'
require 'saxon/xslt/executable'

module Saxon::XSLT
  RSpec.describe Executable do
    let(:processor) { Saxon::Processor.create }
    let(:static_context) { StaticContext.new }
    let(:xsl_source) { fixture_source('eg.xsl') }
    let(:xslte) { processor.to_java.newXsltCompiler.compile(xsl_source.to_java) }

    describe "instantiating" do
      it "requires a Java XsltExecutable and a Saxon::XSLT::StaticContext" do
        expect(described_class.new(xslte, static_context)).to be_a(Saxon::XSLT::Executable)
      end
    end

    describe "instances" do
      specify "return the underlying Java XPathExecutable when asked" do
        instance = described_class.new(xslte, static_context)

        expect(instance.to_java).to be(xslte)
      end
    end

    describe "executing XSLT" do
      let(:compiler) { processor.xslt_compiler }

      context "a simple default-mode apply-templates transform" do
        subject { compiler.compile(xsl_source.to_java) }
        let(:context) { fixture_doc(processor, 'eg.xml') }

        specify "returns a result which provides the output, correctly serialized, as a string" do
          result = subject.apply_templates(context)

          expect(result.to_s.strip).to eq('<output/>')
        end
      end
    end
  end
end
