require 'saxon/qname'

RSpec.describe Saxon::QName do
  describe "instantiating" do
    specify "from a Clark notation string" do
      expect(Saxon::QName.clark('{http://example.org/}fnord').local_name).to eq('fnord')
    end

    specify "from an EQName notation string" do
      expect(Saxon::QName.eqname('Q{http://example.org/}fnord').local_name).to eq('fnord')
    end

    specify "from a prefix, URI, and local name" do
      expect(Saxon::QName.create(local_name: 'el', prefix: 'pre', uri: 'http://example.org/').local_name).to eq('el')
    end

    specify "from a URI and local name" do
      expect(Saxon::QName.create(local_name: 'el', uri: 'http://example.org/').local_name).to eq('el')
    end

    specify "from a local name" do
      expect(Saxon::QName.create(local_name: 'el').local_name).to eq('el')
    end

    context "with invalid options" do
      it "cannot use just a prefix and URI" do
        expect { Saxon::QName.create(prefix: 'pre', uri: 'http://example.org/') }.to raise_error(ArgumentError)
      end

      it "cannot use just a prefix" do
        expect { Saxon::QName.create(prefix: 'pre') }.to raise_error(ArgumentError)
      end

      it "cannot use just a URI" do
        expect { Saxon::QName.create(uri: 'http://example.org/') }.to raise_error(ArgumentError)
      end
    end
  end

  describe "instances" do
    subject { Saxon::QName.create(local_name: 'el', prefix: 'pre', uri: 'http://example.org/') }

    it "can return its local name" do
      expect(subject.local_name).to eq('el')
    end

    it "can return its prefix" do
      expect(subject.prefix).to eq('pre')
    end

    it "can return its URI" do
      expect(subject.uri).to eq('http://example.org/')
    end

    it "can return a Clark notation representation of itself" do
      expect(subject.clark).to eq('{http://example.org/}el')
    end

    it "can return an EQName notation representation of itself" do
      expect(subject.eqname).to eq('Q{http://example.org/}el')
    end

    context "comparison" do
      specify "two QNames with the same NS URI and name are equal, prefix is ignored" do
        expect(subject).to eq(Saxon::QName.clark("{http://example.org/}el"))
      end
    end
  end
end
