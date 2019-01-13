require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'
require 'saxon/xpath/executable'

module Saxon::XPath
  RSpec.describe Executable do
    let(:processor) { Saxon::Processor.create }

    describe "instantiating" do
      it "requires a Java XPathExecutable" do
        xpe = processor.to_java.newXPathCompiler.compile('/')

        expect(described_class.new(xpe)).to be_a(Saxon::XPath::Executable)
      end
    end

    describe "instances" do
      specify "return the underlying Java XPathExecutable when asked" do
        xpe = processor.to_java.newXPathCompiler.compile('/')

        instance = described_class.new(xpe)

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

        specify "returns the expected node as an enumerable" do
          expect(subject.run(context).map { |xdm_node|
            xdm_node.node_name
          }).to eq([Saxon::QName.clark('doc')])
        end
      end
    end
  end
end
