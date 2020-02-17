require 'saxon/serializer'
require 'saxon/processor'
require 'saxon/source'
require 'tmpdir'
require 'stringio'

module Saxon
  RSpec.describe Serializer::Destination do
    let(:processor) { Saxon::Processor.create }
    let(:xslt) {
      processor.xslt_compiler.compile(fixture_source('element.xsl'))
    }
    let(:s9_transformer) {
      xslt.to_java.load30
    }
    let(:invocation_lambda) {
      ->(s9_destination) {
        s9_transformer.callTemplate(Saxon::QName.clark('{http://www.w3.org/1999/XSL/Transform}initial-template').to_java, s9_destination)
      }
    }
    let(:s9_serializer) { processor.to_java.newSerializer }

    describe "creating an instance" do
      specify "requires an S9API::Serializer instance and an invocation lambda" do
        expect(described_class.new(s9_serializer, invocation_lambda)).to be_a(described_class)
      end

      specify "instance-execs a supplied block in order to configure the serializer" do
        destination = described_class.new(s9_serializer, invocation_lambda) {
          output_property[:indent] = 'yes'
        }
        expect(destination.output_property[:indent]).to eq('yes')
      end
    end

    describe "instances" do
      subject { described_class.new(s9_serializer, invocation_lambda) }

      specify "can serialize to a string" do
        expect(subject.serialize).to eq('<?xml version="1.0" encoding="UTF-8"?><element/>')
      end

      specify "can serialize to an IO" do
        result_io = StringIO.new

        subject.serialize(result_io)

        expect(result_io.string).to eq('<?xml version="1.0" encoding="UTF-8"?><element/>')
      end

      specify "can serialize directly to a file" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'f.xml')

          subject.serialize(path)

          expect(File.read(path)).to eq('<?xml version="1.0" encoding="UTF-8"?><element/>')
        end
      end
    end
  end
end