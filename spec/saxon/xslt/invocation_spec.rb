require 'saxon/processor'
require 'saxon/source'
require 'saxon/xslt'
require 'tmpdir'

module Saxon
  RSpec.describe XSLT::Invocation do
    let(:processor) { Processor.create }
    let(:compiler) { processor.xslt_compiler }
    let(:xsl_source) { fixture_source('apply-templates.xsl') }
    let(:xml_source) { fixture_source('eg.xml') }
    let(:xslte) { compiler.compile(xsl_source) }

    subject { xslte.apply_templates(xml_source) }

    context "directly serializing the invocation result" do
      specify "omits the XML declaration as requested by xsl:output" do
        expect(subject.serialize).to eq('<output/>')
      end

      specify "can write directly to a file" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'f.xml')

          subject.serialize(path)

          expect(File.read(path)).to eq('<output/>')
        end
      end

      specify "to_s returns the serialized output" do
        expect(subject.to_s).to eq('<output/>')
      end

      specify "can be passed a block that overrides xsl:output-set serialization options" do
        expect(subject.serialize {
          output_property[:omit_xml_declaration] = 'no'
        }).to eq('<?xml version="1.0" encoding="UTF-8"?><output/>')
      end
    end

    context "returning the invocation result as an XDM Value" do
      specify "returns the document wrapped as an XDM node for the example XSLT" do
        result_value = subject.xdm_value

        expect(result_value.node_kind).to eq(:document)

        root_element = result_value.each.first
        expect(root_element.node_kind).to eq(:element)
        expect(root_element.node_name).to eq(Saxon::QName.clark('output'))
      end

      specify "doesn't perform sequence normalisation if raw was passed" do
        result_value = xslte.apply_templates(xml_source, raw: true).xdm_value

        expect(result_value.node_kind).to eq(:element)
        expect(result_value.node_name).to eq(Saxon::QName.clark('output'))
      end
    end

    context "sending the invocation result to a supplied SAX ContentHandler"
    context "sending the invocation result to a supplied Destination"
  end
end

#     DOMDestination, NullDestination
#     SAXDestinations
#     , SchemaValidator,
#     SchemaValidatorImpl,
#     Serializer, TeeDestination, XdmDestination,
#     XMLStreamWriterDestination