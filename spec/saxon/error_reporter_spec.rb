require 'saxon/processor'
require 'saxon/error_reporter'

module Saxon
  RSpec.describe ErrorReporter do
    let(:processor) { Saxon::Processor.create }
    let(:xslt_compiler) { processor.xslt_compiler }
    let(:xml_source) { fixture_source('eg.xml') }

    context "given a dynamic error" do
      context "when set up with a block" do
        specify "the block has an XmlProcessingError instance passed to it" do
          errors = []
          xslt = xslt_compiler.compile(fixture_source('dynamic-error.xsl')) {
            error_reporter { |error|
              errors << error
            }
          }

          begin
            xslt.apply_templates(xml_source).xdm_value
          rescue Exception => e
          end

          expect(errors.first).to be_a(Saxon::XMLProcessingError)
        end
      end
    end

    context "given a warning" do
      context "when set up with a block" do
        specify "the block has an XmlProcessingError instance passed to it" do
          errors = []
          xslt = xslt_compiler.compile(fixture_source('ambiguity-warning.xsl')) {
            error_reporter { |error|
              errors << error
            }
          }

          xslt.apply_templates(xml_source).xdm_value

          expect(errors.size).to eq(1)
          error = errors.first
          expect(error.warning?).to be(true)
          expect(error).to be_a(Saxon::XMLProcessingError)
        end
      end

      context "when set up with an object instance responding to #call" do
        class TestErrorReporter
          attr_reader :errors

          def initialize
            @errors = []
          end

          def call(error)
            errors << error
          end
        end

        specify "the instance is called with an XmlProcessingError instance" do
          reporter = TestErrorReporter.new

          xslt = xslt_compiler.compile(fixture_source('ambiguity-warning.xsl')) {
            error_reporter(reporter)
          }

          xslt.apply_templates(xml_source).xdm_value

          expect(reporter.errors.size).to eq(1)
          error = reporter.errors.first
          expect(error.warning?).to be(true)
          expect(error).to be_a(Saxon::XMLProcessingError)
        end
      end
    end
  end
end
