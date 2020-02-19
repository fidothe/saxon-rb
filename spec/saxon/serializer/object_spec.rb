require 'saxon/serializer'
require 'saxon/processor'
require 'saxon/source'
require 'saxon/xdm'
require 'tmpdir'
require 'stringio'

module Saxon
  RSpec.describe Serializer::Object do
    let(:processor) { Saxon::Processor.create }
    let(:s9_serializer) { processor.to_java.newSerializer }

    describe "creating an instance" do
      it "requires a Saxon::Processor instance" do
        expect(described_class.new(s9_serializer)).to be_a(described_class)
      end

      specify "instance-execs a supplied block in order to configure the serializer" do
        serializer = described_class.new(s9_serializer) {
          output_property[:indent] = 'yes'
        }
        expect(serializer.output_property[:indent]).to eq('yes')
      end
    end

    describe "instances" do
      let(:xdm_node) { processor.document_builder.build(Saxon::Source.from_string('<doc/>')) }
      let(:xdm_value) { XDM.Value([1, 2]) }
      let(:xdm_item) { XDM.Item('a') }

      subject {
        described_class.new(s9_serializer) {
          output_property[:indent] = 'no'
          output_property[:omit_xml_declaration] = 'no'
        }
      }

      it "holds a reference to an actual Saxon Java Serializer instance" do
        expect(subject.to_java).to be(s9_serializer)
      end

      context "serializing" do
        context "XDM::Nodes" do
          specify "to an IO" do
            io = StringIO.new

            subject.serialize(xdm_node, io)

            expect(io.string).to eq('<?xml version="1.0" encoding="UTF-8"?><doc/>')
          end

          specify "to a string" do
            expect(subject.serialize(xdm_node)).to eq(
              '<?xml version="1.0" encoding="UTF-8"?><doc/>'
            )
          end

          specify "to a string with a requested encoding of UTF-16" do
            subject.output_property[:encoding] = 'UTF-16'

            result = subject.serialize(xdm_node)
            expect(result.encoding).to eq(Encoding::UTF_16)
            expect(result).to eq('<?xml version="1.0" encoding="UTF-16"?><doc/>'.encode(Encoding::UTF_16))
          end

          specify "to a file path" do
            Dir.mktmpdir do |dir|
              path = File.join(dir, 'f.xml')

              subject.serialize(xdm_node, path)

              expect(File.read(path)).to eq('<?xml version="1.0" encoding="UTF-8"?><doc/>')
            end
          end
        end

        context "XDM::Values" do
          subject {
            described_class.new(s9_serializer) {
              output_property[:omit_xml_declaration] = 'yes'
            }
          }

          specify "to an IO" do
            io = StringIO.new

            subject.serialize(xdm_value, io)

            expect(io.string).to eq('1 2')
          end

          specify "to a string" do
            expect(subject.serialize(xdm_value)).to eq('1 2')
          end

          specify "to a file path" do
            Dir.mktmpdir do |dir|
              path = File.join(dir, 'f.txt')

              subject.serialize(xdm_value, path)

              expect(File.read(path)).to eq('1 2')
            end
          end
        end

        context "XDM::Items" do
          subject {
            described_class.new(s9_serializer) {
              output_property[:omit_xml_declaration] = 'yes'
            }
          }

          specify "to an IO" do
            io = StringIO.new

            subject.serialize(xdm_item, io)

            expect(io.string).to eq('a')
          end

          specify "to a string" do
            expect(subject.serialize(xdm_item)).to eq('a')
          end

          specify "to a file path" do
            Dir.mktmpdir do |dir|
              path = File.join(dir, 'f.txt')

              subject.serialize(xdm_item, path)

              expect(File.read(path)).to eq('a')
            end
          end
        end
      end
    end
  end
end