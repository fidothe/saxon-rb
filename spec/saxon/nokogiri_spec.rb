require 'saxon/processor'
require 'saxon/nokogiri'

module Saxon
  RSpec.describe XSLT do
    describe "XSLT 1 Nokogiri/saxon-xslt compatible stylesheet processing invocation" do
      let(:processor) { Saxon::Processor.create }
      let(:xslt_source) { Saxon::Source.create(fixture_path('eg.xsl')) }
      let(:xml_source) { Saxon::Source.create('<input/>') }
      let(:doc) { processor.document_builder.build(xml_source) }
      let(:xslt) { processor.xslt_compiler.compile(xslt_source) }

      def match_global_parameters(params)
        satisfy { |args|
          expect(args[:global_parameters]).to eq(params)
        }
      end

      specify "Calling #transform passes param args through correctly to #apply_templates" do
        expect(xslt).to receive(:apply_templates).with(eq(doc), match_global_parameters({
          Saxon::QName.clark('param') => Saxon::XDM.AtomicValue('1')
        })).and_call_original

        xslt.transform(doc, ['param', '1'])
      end

      specify "Calling #apply_to serializes the result of calling #transform" do
        expect(xslt.apply_to(doc, ['testparam', 'testval'])).to eq('<output>testval</output>')
      end

      specify "Calling #serialize serializes an XML node according to the xsl:output rules in the stylesheet" do
        expect(xslt.serialize(doc)).to eq('<input/>')
      end
    end
  end
end