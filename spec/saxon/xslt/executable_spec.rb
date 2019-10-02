require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'
require 'saxon/xslt/executable'

module Saxon::XSLT
  RSpec.describe Executable do
    let(:processor) { Saxon::Processor.create }
    let(:evaluation_context) { EvaluationContext.new }
    let(:xsl_source) { fixture_source('eg.xsl') }
    let(:xml_source) { fixture_source('eg.xml') }
    let(:xslte) { processor.to_java.newXsltCompiler.compile(xsl_source.to_java) }

    describe "instantiating" do
      it "requires a Java XsltExecutable and a Saxon::XSLT::EvaluationContext" do
        expect(described_class.new(xslte, evaluation_context)).to be_a(Saxon::XSLT::Executable)
      end
    end

    describe "instances" do
      specify "return the underlying Java XsltExecutable when asked" do
        instance = described_class.new(xslte, evaluation_context)

        expect(instance.to_java).to be(xslte)
      end

      context "the evaluation context" do
      end
    end

    describe "executing XSLT" do
      let(:compiler) { processor.xslt_compiler }

      context "via apply-templates" do
        subject { compiler.compile(xsl_source) }

        context "a simple default-mode transform" do
          specify "returns a result which provides the output, and gives access to the XDM document node" do
            result = subject.apply_templates(xml_source)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:document)
          end

          specify "returns a result which provides the output, correctly serialized, as a string" do
            result = subject.apply_templates(xml_source)

            expect(result.to_s.strip).to eq('<output/>')
          end
        end

        context "a transform with an initial mode set" do
          specify "returns a result which provides the correctly serialized output, given the mode as a string" do
            result = subject.apply_templates(xml_source, mode: 'test')

            expect(result.to_s.strip).to eq('<test-output/>')
          end

          specify "returns a result which provides the correctly serialized output, given the mode as a QName" do
            result = subject.apply_templates(xml_source, mode: Saxon::QName.clark('test'))

            expect(result.to_s.strip).to eq('<test-output/>')
          end

          specify "does not allow an initial mode with a namespace to be set using a string" do
            expect {subject.apply_templates(xml_source, mode: 'test:mode') }.to raise_error(Saxon::QName::PrefixedStringWithoutNSURIError)
          end
        end

        context "a transform which doesn't use a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.apply_templates(xml_source, raw: true)

            expect(result.xdm_value).to be_a(Saxon::XdmNode)
            expect(result.xdm_value.node_kind).to be(:element)
          end
        end
      end

      context "via a named template" do
        subject { compiler.compile(xsl_source) }
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

      context "passing parameters in" do
        let(:xsl_source) { fixture_source('params-eg.xsl') }
        let(:compiler) {
          processor.xslt_compiler {
            static_parameters 'static-param' => 'static overridden'
          }
        }

        context "at compilation time" do
          subject {
            compiler.compile(xsl_source) {
              global_parameters 'global-param' => 'global overridden',
                Saxon::QName.clark('{http://example.org/#ns}qname-global-param') => 2
              initial_template_parameters 'template-param' => 'template param overridden'
              initial_template_tunnel_parameters 'template-tunnel-param' => 'tunnel param overridden'
            }
          }

          specify "all parameter kinds are correctly passed in" do
            result = subject.apply_templates(xml_source)

            expect(result.to_s).to eq(<<-EOS.strip)
<output><static-param>static overridden</static-param><global-param>global overridden</global-param><qname-global-param>2</qname-global-param><template-param>template param overridden</template-param><template-tunnel-param>tunnel param overridden</template-tunnel-param></output>
            EOS
          end
        end

        context "at transformation invocation" do
          subject { compiler.compile(xsl_source) }

          specify "all parameter kinds are correctly passed in" do
            result = subject.apply_templates(xml_source, {
              global_parameters: {
                'global-param' => 'global overridden',
                Saxon::QName.clark('{http://example.org/#ns}qname-global-param') => 2
              },
              initial_template_parameters: {
                'template-param' => 'template param overridden'
              },
              initial_template_tunnel_parameters: {
                'template-tunnel-param' => 'tunnel param overridden'
              }
            })

            expect(result.to_s).to eq(<<-EOS.strip)
<output><static-param>static overridden</static-param><global-param>global overridden</global-param><qname-global-param>2</qname-global-param><template-param>template param overridden</template-param><template-tunnel-param>tunnel param overridden</template-tunnel-param></output>
            EOS
          end
        end
      end
    end
  end
end
