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

      context "via apply-templates" do
        subject { compiler.compile(xsl_source.to_java) }
        let(:context) { fixture_doc(processor, 'eg.xml') }

        context "a simple default-mode transform" do
          specify "returns a result which provides the output, and gives access to the XDM document node" do
            result = subject.apply_templates(context)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:document)
          end

          specify "returns a result which provides the output, correctly serialized, as a string" do
            result = subject.apply_templates(context)

            expect(result.to_s.strip).to eq('<output/>')
          end
        end

        context "a transform with an initial mode set" do
          specify "returns a result which provides the correctly serialized output, given the mode as a string" do
            result = subject.apply_templates(context, mode: 'test')

            expect(result.to_s.strip).to eq('<test-output/>')
          end

          specify "returns a result which provides the correctly serialized output, given the mode as a QName" do
            result = subject.apply_templates(context, mode: Saxon::QName.clark('test'))

            expect(result.to_s.strip).to eq('<test-output/>')
          end

          specify "does not allow an initial mode with a namespace to be set using a string" do
            expect {subject.apply_templates(context, mode: 'test:mode') }.to raise_error(Saxon::QName::PrefixedStringWithoutNSURIError)
          end
        end

        context "a transform which doesn't use a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.apply_templates(context, raw: true)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:element)
          end
        end
      end

      context "via a named template" do
        subject { compiler.compile(xsl_source.to_java) }
        let(:template) { Saxon::QName.clark('by-template') }

        context "with an explicit QName" do
          specify "returns a result which provides the output, and gives access to the XDM document node" do
            result = subject.call_template(template)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:document)
          end

          specify "returns a result which provides the output, correctly serialized, as a string" do
            result = subject.call_template(template)

            expect(result.to_s.strip).to eq('<template/>')
          end
        end

        specify "with a string instead of a QName" do
          result = subject.call_template('by-template')

          expect(result.to_s.strip).to eq('<template/>')
        end

        specify "does not allow a template name with a namespace to be set using a string" do
          expect {subject.call_template('test:template') }.to raise_error(Saxon::QName::PrefixedStringWithoutNSURIError)
        end

        context "a transform which doesn't use a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.call_template(template, raw: true)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:element)
          end
        end
      end
    end
  end
end
