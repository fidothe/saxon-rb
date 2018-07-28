require 'saxon/serializer'
require 'saxon/processor'
require 'saxon/source'
require 'stringio'

RSpec.describe Saxon::Serializer do
  let(:processor) { Saxon::Processor.create }
  let(:s9_serializer) { processor.to_java.newSerializer }

  describe "creating an instance" do
    it "requires a Saxon::Processor instance" do
      expect(Saxon::Serializer.new(s9_serializer)).to be_a(Saxon::Serializer)
    end
  end

  describe "instances" do
    subject { Saxon::Serializer.new(s9_serializer) }

    it "holds a reference to an actual Saxon Java Serializer instance" do
      expect(subject.to_java).to be(s9_serializer)
    end

    describe "getting and setting properties" do
      context "with symbols" do
        it "can set a property" do
          expect(subject.output_property[:indent] = 'yes').to eq('yes')
        end

        it "can get a property" do
          subject.output_property[:indent] = 'yes'
          expect(subject.output_property[:indent]).to eq('yes')
        end
      end
    end

    describe "serialization" do
      let(:xdm_node) { processor.document_builder.build(Saxon::Source.from_string('<doc/>')) }
      let(:io) { StringIO.new }

      context "to an IO-like" do
        before do
          subject.output_property[:indent] = 'no'
          subject.output_property[:omit_xml_declaration] = 'no'
        end

        it "writes an XdmNode" do
          subject.serialize(xdm_node, io)

          expect(io.string).to eq('<?xml version="1.0" encoding="UTF-8"?><doc/>')
        end

        xit "writes an XdmValue" do
        end

        xit "writes an XdmItem" do
        end
      end

      context "to a string" do
      end

      context "to a file path" do
      end
    end
  end
end
