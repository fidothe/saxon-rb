require 'saxon/processor'

RSpec.describe Saxon::Processor do
  let(:xsl_file) { File.open(fixture_path('eg.xsl')) }

  context "without explicit configuration" do
    let(:processor) { Saxon::Processor.create }

    it "can return the underlying Saxon Processor" do
      expect(processor.to_java).to respond_to(:new_xslt_compiler)
    end

    it "can return the processor's configuration instance" do
      expect(processor.config).to be_a(Saxon::Configuration)
    end
  end

  context "with explicit configuration" do
    it "works, given a valid config XML file", focus: true do
      processor = Saxon::Processor.create(File.open(fixture_path('config.xml')))

      expect(processor.config[:xml_version]).to eq("1.1")
    end

    it "works, given a Saxon::Configuration object" do
      config = Saxon::Configuration.create
      config[:line_numbering] = true
      processor = Saxon::Processor.create(config)

      expect(processor.config[:line_numbering]).to be(true)
    end
  end

  context "the default processor" do
    it "is created on demand" do
      expect(Saxon::Processor.default).to be_a(Saxon::Processor)
    end

    it "returns the same processor instance if requested repeatedly" do
      expected = Saxon::Processor.default
      expect(Saxon::Processor.default).to be(expected)
    end
  end

  context "instances" do
    subject { Saxon::Processor.create }

    context "DocumentBuilders" do
      it "can return a new DocumentBuilder" do
        expect(subject.document_builder).to be_a(Saxon::DocumentBuilder)
      end

      it "the return DocumentBuilder is correctly instantiated" do
        expect(subject.document_builder.to_java).to respond_to(:build)
      end
    end
  end
end
