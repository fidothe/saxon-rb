require 'saxon/processor'
require 'saxon/source'
require 'saxon/document_builder'
require 'uri'

RSpec.describe Saxon::DocumentBuilder do
  let(:processor) { Saxon::Processor.create }

  it "is instantiated from a Processor factory method" do
    expect(processor.document_builder).to be_a(Saxon::DocumentBuilder)
  end

  context "configuration" do
    subject { described_class.create(processor) }

    context "line numbering" do
      specify "is reported off by default" do
        expect(subject.line_numbering?).to be(false)
      end

      specify "can be switched on for this builder" do
        subject.line_numbering = true
        expect(subject.line_numbering?).to be(true)
      end
    end

    context "the default base URI" do
      specify "defaults to nil" do
        expect(subject.base_uri).to be(nil)
      end

      specify "can be set with a valid string" do
        subject.base_uri = 'http://example.org/'
        expect(subject.base_uri).to eq(URI('http://example.org/'))
      end

      specify "can be set with a valid URI" do
        subject.base_uri = URI('http://example.org/')
        expect(subject.base_uri).to eq(URI('http://example.org/'))
      end
    end

    context "whitespace stripping policy" do
      specify "defaults to :unspecified" do
        expect(subject.whitespace_stripping_policy).to eq(:unspecified)
      end

      specify "can be set with a valid policy name" do
        subject.whitespace_stripping_policy = :all
        expect(subject.whitespace_stripping_policy).to eq(:all)
      end

      context "custom polcies" do
        before do
          subject.whitespace_stripping_policy = ->(qname) {
            qname.clark == 'hello'
          }
        end

        specify "can be created using a 1-arg lambda" do
          expect(subject.whitespace_stripping_policy).to be_a(Saxon::S9API::WhitespaceStrippingPolicy)
        end

        specify "are correctly interpreted by the document builder" do
          source = Saxon::Source.from_string("<hello>    </hello>", base_uri: "http://example.org/")
          doc = subject.build(source)
          root = doc.first

          expect(root.first).to be(nil)
        end
      end

      specify "can be passed in as a net.sf.saxon.s9api.WhitespaceStrippingPolicy" do
        policy = Saxon::S9API::WhitespaceStrippingPolicy.makeCustomPolicy(->(s9_qname) { false })
        subject.whitespace_stripping_policy = policy

        expect(subject.whitespace_stripping_policy).to be_a(Saxon::S9API::WhitespaceStrippingPolicy)
      end

      specify "any other values raise an InvalidWhitespaceStrippingPolicyError" do
        expect { subject.whitespace_stripping_policy = :badly }.to raise_error(Saxon::InvalidWhitespaceStrippingPolicyError)
      end
    end

    context "DTD validation" do
      specify "is off by default" do
        expect(subject.dtd_validation?).to be(false)
      end

      specify "can be turned on" do
        subject.dtd_validation = true

        expect(subject.dtd_validation?).to be(true)
      end
    end
  end

  context "config at initialization time via instance-exec'ing a DSL block" do
    specify "sets line_numbering correctly" do
      builder = described_class.create(processor) {
        line_numbering true
      }

      expect(builder.line_numbering?).to be(true)
    end

    specify "sets whitespace_stripping_policy correctly" do
      builder = described_class.create(processor) {
        whitespace_stripping_policy :all
      }

      expect(builder.whitespace_stripping_policy).to eq(:all)
    end

    specify "sets dtd_validation correctly" do
      builder = described_class.create(processor) {
        dtd_validation true
      }

      expect(builder.dtd_validation?).to be(true)
    end

    specify "sets base_uri correctly" do
      builder = described_class.create(processor) {
        base_uri 'http://example.org/'
      }

      expect(builder.base_uri).to eq(URI('http://example.org/'))
    end
  end

  context "parsing XML documents" do
    subject { processor.document_builder }

    it "parses a document given a Source" do
      source = Saxon::Source.from_string("<doc/>", base_uri: "http://example.org/")
      doc = subject.build(source)

      expect(doc).to be_a(Saxon::XDM::Node)
    end
  end
end
