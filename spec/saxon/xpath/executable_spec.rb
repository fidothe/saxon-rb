require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'
require 'saxon/xpath/executable'

module Saxon::XPath
  RSpec.describe Executable do
    let(:processor) { Saxon::Processor.create }
    let(:static_context) { StaticContext.new }
    let(:xpe) { processor.to_java.newXPathCompiler.compile('/') }

    describe "instantiating" do
      it "requires a Java XPathExecutable and a Saxon::XPath::StaticContext" do
        expect(described_class.new(xpe, static_context)).to be_a(Saxon::XPath::Executable)
      end
    end

    describe "instances" do
      specify "return the underlying Java XPathExecutable when asked" do
        instance = described_class.new(xpe, static_context)

        expect(instance.to_java).to be(xpe)
      end
    end

    describe "executing queries" do
      let(:doc_builder) { processor.document_builder }
      let(:source) { Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/") }
      let(:context) { doc_builder.build(source) }
      let(:compiler) { processor.xpath_compiler }

      context "a simple query" do
        subject { compiler.compile('/doc') }

        context "being evaluated it to return an Enumerator over the contents of the XDM Value" do
          specify "returns the expected value" do
            expect(subject.as_enum(context).map { |xdm_node|
              xdm_node.node_name
          }.to_a).to eq([Saxon::QName.clark('doc')])
          end

          specify "returns a non-node value correctly" do
            expect(compiler.compile("'a'").as_enum(context).to_a).to eq([Saxon::XDM.AtomicValue('a')])
          end
        end

        context "being evaluated it to return an XDM::Value" do
          specify "returns the expected value" do
            expect(subject.evaluate(context).node_name).to eq(Saxon::QName.clark('doc'))
          end

          specify "returns a non-node value correctly" do
            expect(compiler.compile("'a'").evaluate(context)).to eq(Saxon::XDM.AtomicValue('a'))
          end
        end
      end
    end
  end
end
