require 'saxon/xdm_node'
require 'saxon/processor'
require 'saxon/source'

RSpec.describe Saxon::XdmNode do
  let(:doc_builder) { Saxon::Processor.create.document_builder }
  let(:source) { Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/") }

  context "parsing XML documents" do
    it "parses a document given a Source" do
      doc = doc_builder.build(source)

      expect(doc).to be_a(Saxon::XdmNode)
    end
  end

  describe "instances" do
    subject { doc_builder.build(source) }

    it "returns the underlying Java XdmNode" do
      expect(subject.to_java).to be_a(Saxon::S9API::XdmNode)
    end
  end
end
