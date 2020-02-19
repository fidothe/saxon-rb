require 'saxon/processor'
require 'saxon/serializer/output_properties'

module Saxon::Serializer
  class Harness
    include Saxon::Serializer::OutputProperties

    attr_reader :s9_serializer

    def initialize(s9_serializer)
      @s9_serializer = s9_serializer
    end
  end

  RSpec.describe "getting and setting properties" do
    let(:processor) { Saxon::Processor.create }
    subject {
      Harness.new(processor.to_java.newSerializer)
    }

    context "with symbols" do
      it "can set a property" do
        expect(subject.output_property[:indent] = 'yes').to eq('yes')
      end

      it "can get a property" do
        subject.output_property[:indent] = 'yes'
        expect(subject.output_property[:indent]).to eq('yes')
      end

      context "fetching a property" do
        it "raises KeyError if property does not exist" do
          expect { subject.output_property.fetch(:balloon) }.to raise_error(KeyError)
        end

        it "fetches a set property" do
          subject.output_property[:indent] = 'yes'
          expect(subject.output_property.fetch(:indent)).to eq('yes')
        end

        it "allows a default to be set if the property has not been explicitly set" do
          expect(subject.output_property.fetch(:indent, '1')).to eq('1')
        end
      end
    end
  end
end