require 'saxon/xdm_node'
require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'

RSpec.describe Saxon::XdmNode do
  let(:doc_builder) { Saxon::Processor.create.document_builder }
  let(:source) { Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/") }
  let(:doc_node) { doc_builder.build(source) }

  context "parsing XML documents" do
    it "parses a document given a Source" do
      doc = doc_builder.build(source)

      expect(doc).to be_a(Saxon::XdmNode)
    end
  end

  describe "instances" do
    subject { doc_node }

    it "returns the underlying Java XdmNode" do
      expect(subject.to_java).to be_a(Saxon::S9API::XdmNode)
    end

    it "can iterate across its children" do
      expect(subject.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark('doc')])
    end

    it "can return an axis iterator for itself" do
      expect(subject.axis_iterator(:child).map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark('doc')])
    end

    context "when compared, nodes" do
      let(:n2) { Saxon::XdmNode.new(subject.to_java) }

      specify "are #== equal to another instance representing the same node" do
        expect(subject == n2).to be(true)
      end

      specify "are #eql? equal to another instance representing the same node" do
        expect(subject.eql?(n2)).to be(true)
      end

      specify "have the same hash as another instance representing the same node" do
        expect(subject.hash).to eq(n2.hash)
      end
    end

    context "element nodes" do
      subject { doc_node.each.first }

      it "can return their node name as a QName" do
        expect(subject.node_name).to eq(Saxon::QName.clark('doc'))
      end
    end
  end
end