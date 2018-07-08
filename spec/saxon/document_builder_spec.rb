require 'spec_helper'
require 'saxon/processor'
require 'saxon/source'
require 'saxon/document_builder'

RSpec.describe Saxon::DocumentBuilder do
  it "is instantiated from a Processor factory method" do
    processor = Saxon::Processor.create
    expect(processor.document_builder).to be_a(Saxon::DocumentBuilder)
  end

  context "parsing XML documents" do
    subject { Saxon::Processor.create.document_builder }

    it "parses a document given a Source" do
      source = Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/")
      doc = subject.build(source)

      expect(doc).to be_a(Saxon::XdmNode)
    end
  end
end
