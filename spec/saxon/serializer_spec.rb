require 'saxon/serializer'
require 'saxon/processor'
require 'saxon/source'
require 'tmpdir'
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

    describe "serialization" do
      let(:xdm_node) { processor.document_builder.build(Saxon::Source.from_string('<doc/>')) }

      before do
        subject.output_property[:indent] = 'no'
        subject.output_property[:omit_xml_declaration] = 'no'
      end

      context "to an IO-like" do
        let(:io) { StringIO.new }

        it "writes an XDM::Node" do
          subject.serialize(xdm_node, io)

          expect(io.string).to eq('<?xml version="1.0" encoding="UTF-8"?><doc/>')
        end

        xit "writes an XDM::Value" do
        end

        xit "writes an XDM::Item" do
        end
      end

      context "to a string" do
        it "writes an XDM::Node" do
          expect(subject.serialize(xdm_node)).to eq(
            '<?xml version="1.0" encoding="UTF-8"?><doc/>'
          )
        end

        it "returns a string with the correct encoding" do
          subject.output_property[:encoding] = 'UTF-16'

          result = subject.serialize(xdm_node)
          expect(result.encoding).to eq(Encoding::UTF_16)
          expect(result).to eq('<?xml version="1.0" encoding="UTF-16"?><doc/>'.encode(Encoding::UTF_16))
        end

        xit "writes an XDM::Value" do
        end

        xit "writes an XDM::Item" do
        end
      end

      context "to a file path" do
        it "writes an XDM::Node" do
          Dir.mktmpdir do |dir|
            path = File.join(dir, 'f.xml')

            subject.serialize(xdm_node, path)

            expect(File.read(path)).to eq('<?xml version="1.0" encoding="UTF-8"?><doc/>')
          end
        end

        xit "writes an XDM::Value" do
        end

        xit "writes an XDM::Item" do
        end
      end
    end
  end
end
