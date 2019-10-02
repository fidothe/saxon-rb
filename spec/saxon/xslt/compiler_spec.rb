require 'saxon/processor'
require 'saxon/source'
require 'saxon/xslt/compiler'

module Saxon
  RSpec.describe XSLT::Compiler do
    let(:processor) { Processor.create }

    it "is instantiated from a Processor factory method" do
      expect(processor.xslt_compiler).to be_a(XSLT::Compiler)
    end

    describe "producing a compiler" do
      context "without data in the static context" do
        it "can be produced simply from a Saxon::Processor" do
          expect(XSLT::Compiler.create(processor)).to be_a(XSLT::Compiler)
        end
      end

      context "collations" do
        it "can have default collation set" do
          compiler = XSLT::Compiler.create(processor) {
            default_collation 'http://example.org/collation'
          }

          expect(compiler.default_collation).to eq('http://example.org/collation')
        end
      end

      context "compile-time parameters" do
        it "can have compile-time (static) parameters declared" do
          compiler = XSLT::Compiler.create(processor) {
            static_parameters({
              'no_ns_param_1' => 'inferred string type',
              :no_ns_param_2 => 1,
              QName.clark('{http://example.org/#ns}param') => XDM::AtomicValue.create(1.0)
            })
          }

          expect(compiler.static_parameters).to eq({
            QName.clark('no_ns_param_1') => XDM::AtomicValue.create('inferred string type'),
            QName.clark('no_ns_param_2') => XDM::AtomicValue.create(1),
            QName.clark('{http://example.org/#ns}param') => XDM::AtomicValue.create(1.0)
          })
        end
      end

      context "run-time parameters" do
        context "global parameters" do
          specify "can be declared" do
            compiler = XSLT::Compiler.create(processor) {
              global_parameters 'a' => 'string'
            }

            expect(compiler.global_parameters).to eq({
              QName.clark('a') => XDM::AtomicValue.create('string')
            })
          end

          specify "cannot redeclare a parameter set statically already" do
            expect {
              XSLT::Compiler.create(processor) {
                static_parameters 'a' => 'other value'
                global_parameters 'a' => 'string'
              }
            }.to raise_error(XSLT::GlobalAndStaticParameterClashError)
          end
        end

        it "can have non-tunneling parameters for the initial template declared" do
          compiler = XSLT::Compiler.create(processor) {
            initial_template_parameters 'a' => 'string'
          }

          expect(compiler.initial_template_parameters).to eq({
            QName.clark('a') => XDM::AtomicValue.create('string')
          })
        end

        it "can have tunneling parameters for the initial template declared" do
          compiler = XSLT::Compiler.create(processor) {
            initial_template_tunnel_parameters 'a' => 'string'
          }

          expect(compiler.initial_template_tunnel_parameters).to eq({
            QName.clark('a') => XDM::AtomicValue.create('string')
          })
        end
      end

      context "deriving a new Compiler from an existing one" do
        let(:base) {
          described_class.create(processor) {
            default_collation 'http://example.org/collation'
            static_parameters 'a' => 1
          }
        }

        specify "the existing properties are preserved" do
          compiler = base.create {
            static_parameters 'b' => 2
          }

          expect(compiler.static_parameters).to eq({
            Saxon::QName.clark('a') => Saxon::XDM::AtomicValue.create(1),
            Saxon::QName.clark('b') => Saxon::XDM::AtomicValue.create(2)
          })

          expect(compiler.default_collation).to eq('http://example.org/collation')
        end

        specify "existing properties can be overwritten" do
          compiler = base.create {
            default_collation nil
            static_parameters 'a' => 2
          }

          expect(compiler.static_parameters).to eq({
            Saxon::QName.clark('a') => Saxon::XDM::AtomicValue.create(2)
          })

          expect(compiler.default_collation).to be_nil
        end

        specify "cannot declare a global parameter already set statically" do
          expect {
            base.create {
              global_parameters 'a' => 'other value'
            }
          }.to raise_error(XSLT::GlobalAndStaticParameterClashError)
        end

        specify "cannot declare a static parameter already set globally" do
          base = described_class.create(processor) {
            global_parameters 'a' => 1
          }
          expect {
            base.create {
              static_parameters 'a' => 'other value'
            }
          }.to raise_error(XSLT::GlobalAndStaticParameterClashError)
        end
      end
    end

    describe "producing an XST::Executable" do
      subject { described_class.create(processor) }
      let(:xsl_source) { fixture_source('eg.xsl') }

      specify "requires a Saxon::Source containing the XSLT source" do
        expect(subject.compile(xsl_source)).to be_a(XSLT::Executable)
      end

      specify "the evaluation context for the Executable can be modified at creation time, without affecting the Compiler" do
        executable = subject.compile(xsl_source) {
          global_parameters 'a' => 1
        }

        expect(executable.global_parameters).to eq({
          Saxon::QName.clark('a') => Saxon::XDM::AtomicValue.create(1)
        })

        expect(subject.global_parameters).to eq({})
      end
    end
  end
end
