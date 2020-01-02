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
    end

    describe "executing XSLT" do
      let(:compiler) { processor.xslt_compiler }

      context "via apply-templates" do
        let(:xsl_source) { fixture_source('apply-templates.xsl') }
        subject { compiler.compile(xsl_source) }

        context "a simple default-mode transform" do
          specify "returns a result which provides the output, and gives access to the XDM document node" do
            result = subject.apply_templates(xml_source)

            expect(result.xdm_value).to be_a(Saxon::XDM::Node)
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

            expect(result.to_s.strip).to eq('<mode-output/>')
          end

          specify "returns a result which provides the correctly serialized output, given the mode as a QName" do
            result = subject.apply_templates(xml_source, mode: Saxon::QName.clark('test'))

            expect(result.to_s.strip).to eq('<mode-output/>')
          end

          specify "does not allow an initial mode with a namespace to be set using a string" do
            expect { subject.apply_templates(xml_source, mode: 'test:mode') }.to raise_error(Saxon::QName::PrefixedStringWithoutNSURIError)
          end
        end

        context "passing parameters in" do
          let(:compiler) {
            processor.xslt_compiler {
              static_parameters 'static-param' => 'i'
              global_parameters 'global-param' => '1'
              initial_template_parameters 'template-param' => 'a'
              initial_template_tunnel_parameters 'template-tunnel-param' => 'A'
            }
          }
          let(:executable) {
            compiler.compile(xsl_source) {
              static_parameters 'static-param' => 'ii'
              global_parameters 'global-param' => '2'
              initial_template_parameters 'template-param' => 'b'
              initial_template_tunnel_parameters 'template-tunnel-param' => 'B'
            }
          }

          specify "all parameter types can be passed in at compiler creation time" do
            executable = compiler.compile(xsl_source)
            result = executable.apply_templates(xml_source)

            expect(result.to_s.strip).to eq('<output><s>i</s><g>1</g><t>a</t><tt>A</tt></output>')
          end

          specify "all parameter types can be passed in at compilation time (overriding the earlier set value)" do
            result = executable.apply_templates(xml_source)

            expect(result.to_s.strip).to eq('<output><s>ii</s><g>2</g><t>b</t><tt>B</tt></output>')
          end

          specify "non-static parameter types can be passed in at execution time (overriding an earlier set value)" do
            result = executable.apply_templates(xml_source, {
              global_parameters: {'global-param' => '3'},
              initial_template_parameters: {'template-param' => 'c'},
              initial_template_tunnel_parameters: {'template-tunnel-param' => 'C'}
            })

            expect(result.to_s.strip).to eq('<output><s>ii</s><g>3</g><t>c</t><tt>C</tt></output>')
          end

          specify "static parameters cannot be passed in at execution time" do
            compiler = processor.xslt_compiler
            executable = compiler.compile(xsl_source)
            expect {
              executable.apply_templates(xml_source, {
                static_parameters: {'static-param' => 'value'}
              })
            }.to raise_error(Saxon::XSLT::BadOptionError)
          end
        end

        context "a transform which doesn't use a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.apply_templates(xml_source, raw: true)

            expect(result.xdm_value).to be_a(Saxon::XDM::Node)
            expect(result.xdm_value.node_kind).to be(:element)
          end
        end
      end

      context "via a named template" do
        let(:xsl_source) { fixture_source('call-template.xsl') }
        subject {
          processor.xslt_compiler.compile(xsl_source) {
            initial_template_parameters 'template-param' => '1'
            initial_template_tunnel_parameters 'template-tunnel-param' => '2'
          }
        }

        specify "can invoke a template using a QName" do
          result = subject.call_template(Saxon::QName.clark("{http://example.org/ns}root"))

          expect(result.to_s.strip).to eq("<ns-root-template><t>1</t><tt>2</tt></ns-root-template>")
        end

        specify "can invoke a template using a string nane" do
          result = subject.call_template('root')

          expect(result.to_s.strip).to eq("<root-template><t>1</t><tt>2</tt></root-template>")
        end

        specify "can invoke the default named template" do
          result = subject.call_template

          expect(result.to_s.strip).to eq("<default-template><t>1</t><tt>2</tt></default-template>")
        end

        specify "can invoke a template with the global context item set" do
          doc = processor.XML(xml_source)
          node = processor.xpath_compiler.compile('/root/child').evaluate(doc)

          result = subject.call_template('context', global_context_item: node)

          expect(result.to_s.strip).to eq("<context>woo</context>")
        end

        specify "does not allow a template name with a namespace to be set using a string" do
          expect {subject.call_template('test:template') }.to raise_error(Saxon::QName::PrefixedStringWithoutNSURIError)
        end

        context "a transform which doesn't use a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.call_template(nil, raw: true)

            expect(result.xdm_value).to be_a(Saxon::XDM::Node)
            expect(result.xdm_value.node_kind).to be(:element)
          end
        end
      end

      context "a function" do
        let(:xsl_source) { fixture_source('call-function.xsl') }
        subject { processor.xslt_compiler.compile(xsl_source) }

        specify "can invoke a function" do
          result = subject.call_function(Saxon::QName.clark("{http://example.org/ns}func"), args: [Saxon::XDM.EmptySequence()])

          expect(result.to_s.strip).to eq("<function-result/>")
        end

        context "without using a destination" do
          specify "returns a result which provides the raw XDM value" do
            result = subject.call_function(Saxon::QName.clark("{http://example.org/ns}func"), args: ['a'], raw: true)

            expect(result.xdm_value).to be_a(Saxon::XDM::Node)
            expect(result.xdm_value.node_kind).to be(:element)
          end

          specify "a function which returns an XDM::AtomicValue" do
            result = subject.call_function(Saxon::QName.clark("{http://example.org/ns}int"), raw: true)
            expect(result.xdm_value).to eq(Saxon::XDM.AtomicValue(1))
          end
        end
      end
    end
  end
end
