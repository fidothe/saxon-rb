require 'saxon/source'
require 'stringio'
require 'open-uri'

RSpec.describe Saxon::Source do
  context "instantiating" do
    context "from IO and IO-like objects" do
      it "an IO-like with a path" do
        source = Saxon::Source.from_io(File.open(fixture_path('eg.xml')))

        expect(source.base_uri).to eq(fixture_path('eg.xml'))
      end

      it "an open-uri'd file URI" do
        uri = "file://#{fixture_path('eg.xml')}"
        source = Saxon::Source.from_io(open(uri))

        expect(source.base_uri).to eq(uri)
      end

      it "an open-uri'd http URI", :vcr do
        uri = "http://example.org/"
        source = Saxon::Source.from_io(open(uri))

        expect(source.base_uri).to eq(uri)
      end

      it "an IO-like, without a base URI" do
        input = StringIO.new("<doc/>")
        source = Saxon::Source.from_io(input)

        expect(source.base_uri).to be_nil
      end

      it "an IO-like, with an explicitly-set base URI, the inherent base URI is overridden" do
        source = Saxon::Source.from_io(File.open(fixture_path('eg.xml')), base_uri: '/path/elsewhere')

        expect(source.base_uri).to eq('/path/elsewhere')
      end
    end

    context "from a file path" do
      it "uses the path as the base URI" do
        source = Saxon::Source.from_path(fixture_path('eg.xml'))

        expect(source.base_uri).to eq("file:#{fixture_path('eg.xml')}")
      end

      it "allows the base URI to be overridden" do
        source = Saxon::Source.from_path(fixture_path('eg.xml'), base_uri: '/path/elsewhere')

        expect(source.base_uri).to eq('/path/elsewhere')
      end
    end

    context "from a URI" do
      it "uses the URI as the base URI" do
        source = Saxon::Source.from_uri('http://example.org/')

        expect(source.base_uri).to eq('http://example.org/')
      end

      it "allows the base URI to be overridden" do
        source = Saxon::Source.from_uri('http://example.org/', base_uri: 'http://example.org/other')

        expect(source.base_uri).to eq('http://example.org/other')
      end
    end

    context "from a String" do
      it "with a base URI" do
        source = Saxon::Source.from_string('<doc/>', base_uri: 'http://example.org/')

        expect(source.base_uri).to eq('http://example.org/')
      end

      it "without a base URI" do
        source = Saxon::Source.from_string('<doc/>')

        expect(source.base_uri).to be_nil
      end
    end

    context "from any of the above" do
      specify "a String" do
        expect(Saxon::Source.create('<doc/>')).to be_a(Saxon::Source)
      end

      specify "a URI" do
        expect(Saxon::Source.create('http://example.org/')).to be_a(Saxon::Source)
      end

      specify "a Path" do
        expect(Saxon::Source.create(fixture_path('eg.xml'))).to be_a(Saxon::Source)
      end

      specify "a File" do
        expect(Saxon::Source.create(File.open(fixture_path('eg.xml')))).to be_a(Saxon::Source)
      end

      specify "a Java InputStream" do
        expect(Saxon::Source.create(File.open(fixture_path('eg.xml')).to_inputstream, base_uri: 'http://example.org')).to be_a(Saxon::Source)
      end

      specify "a StringIO" do
        expect(Saxon::Source.create(StringIO.new('<doc/>'))).to be_a(Saxon::Source)
      end
    end
  end

  context "instances" do
    subject { Saxon::Source.from_string('<doc/>') }

    it "returns the underlying StreamSource on to_java" do
      expect(subject.to_java).to be_a(Saxon::JAXP::StreamSource)
    end

    it "closes the underlying InputStream on #close" do
      inputstream_double = double()
      allow(subject).to receive(:inputstream) { inputstream_double }

      expect(inputstream_double).to receive(:close)

      subject.close
      expect(subject.closed?).to be(true)
    end

    it "allows the base_uri to be set" do
      subject.base_uri = 'http://example.org/eg'

      expect(subject.base_uri).to eq('http://example.org/eg')
    end

    it "does not allow itself to return the source if it is closed" do
      subject.close
      expect { subject.consume }.to raise_error(Saxon::SourceClosedError)
    end

    it "provides a block-based interface to simplify closing after use" do
      res = []
      subject.consume { |source|
        res << source.closed?
      }
      res << subject.closed?

      expect(res).to eq([false, true])
    end
  end
end
