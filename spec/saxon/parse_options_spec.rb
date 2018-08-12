require 'saxon/parse_options'

RSpec.describe Saxon::ParseOptions do
  it "is instantiated from a java ParseOptions instance" do
    parse_options = Saxon::ParseOptions.new(Saxon::S9API::ParseOptions.new)
    expect(parse_options).to be_a(Saxon::ParseOptions)
  end

  it "can be instantiated with a default-options ParseOptions by no-arg instantiation" do
    parse_options = Saxon::ParseOptions.new
    expect(parse_options).to be_a(Saxon::ParseOptions)
  end

  context "parser properties" do
    subject { Saxon::ParseOptions.new }

    it "can be set singly by URL" do
      expect(subject.properties['http://xml.org/sax/properties/document-xml-version'] = '1.1').to eq('1.1')
    end

    it "can be fetched singly by URL" do
      subject.properties['http://xml.org/sax/properties/document-xml-version'] = '1.1'

      expect(subject.properties['http://xml.org/sax/properties/document-xml-version']).to eq('1.1')
    end

    it "fetching an unset property when none have been set returns nil" do
      expect(subject.properties['http://xml.org/sax/properties/document-xml-version']).to be_nil
    end

    it "fetching an unset property returns nil" do
      subject.properties['http://xml.org/sax/properties/document-xml-version'] = '1.1'
      expect(subject.properties['http://example.org/null']).to be_nil
    end

    context "acting Enumerable" do
      before do
        subject.properties['http://xml.org/sax/properties/document-xml-version'] = '1.1'
      end

      it "all can be fetched as a hash" do
        expect(subject.properties.to_h).to eq({
          'http://xml.org/sax/properties/document-xml-version' => '1.1'
        })
      end

      it "all can have uri/value iterated across" do
        akku = []

        subject.properties.each { |k, v| akku << [k, v] }

        expect(akku).to eq([
          ['http://xml.org/sax/properties/document-xml-version', '1.1']
        ])
      end

      it "acts Enumerable" do
        expect(subject.properties).to respond_to(:find)
      end

      it "copes when nothing has been set" do
        parse_options = Saxon::ParseOptions.new

        expect(parse_options.properties.to_h).to eq({})
      end
    end
  end

  context "parser features" do
    subject { Saxon::ParseOptions.new }

    it "can be set singly by URL" do
      expect(subject.features['http://xml.org/sax/features/validation'] = true).to be(true)
    end

    it "can be fetched singly by URL" do
      subject.features['http://xml.org/sax/features/validation'] = true

      expect(subject.features['http://xml.org/sax/features/validation']).to be(true)
    end

    it "fetching an unset property when none have been set returns nil" do
      expect(subject.features['http://xml.org/sax/features/validation']).to be_nil
    end

    it "fetching an unset property returns nil" do
      subject.features['http://xml.org/sax/features/validation'] = true

      expect(subject.features['http://example.org/null']).to be_nil
    end

    context "acting Enumerable" do
      before do
        subject.features['http://xml.org/sax/features/validation'] = true
      end

      it "all can be fetched as a hash" do
        expect(subject.features.to_h).to eq({
          'http://xml.org/sax/features/validation' => true
        })
      end

      it "all can have uri/value iterated across" do
        akku = []

        subject.features.each { |k, v| akku << [k, v] }

        expect(akku).to eq([
          ['http://xml.org/sax/features/validation', true]
        ])
      end

      it "acts Enumerable" do
        expect(subject.features).to respond_to(:find)
      end

      it "copes when nothing has been set" do
        parse_options = Saxon::ParseOptions.new

        expect(parse_options.features.to_h).to eq({})
      end
    end
  end
end
