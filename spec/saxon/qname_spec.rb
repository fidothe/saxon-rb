require 'saxon/qname'

module Saxon
  RSpec.describe QName do
    describe "instantiating" do
      specify "from a Clark notation string" do
        expect(QName.clark('{http://example.org/}fnord').local_name).to eq('fnord')
      end

      specify "from an EQName notation string" do
        expect(QName.eqname('Q{http://example.org/}fnord').local_name).to eq('fnord')
      end

      specify "from a prefix, URI, and local name" do
        expect(QName.create(local_name: 'el', prefix: 'pre', uri: 'http://example.org/').local_name).to eq('el')
      end

      specify "from a URI and local name" do
        expect(QName.create(local_name: 'el', uri: 'http://example.org/').local_name).to eq('el')
      end

      specify "from a local name" do
        expect(QName.create(local_name: 'el').local_name).to eq('el')
      end

      context "with invalid options" do
        it "cannot use just a prefix and URI" do
          expect { QName.create(prefix: 'pre', uri: 'http://example.org/') }.to raise_error(ArgumentError)
        end

        it "cannot use just a prefix" do
          expect { QName.create(prefix: 'pre') }.to raise_error(ArgumentError)
        end

        it "cannot use just a URI" do
          expect { QName.create(uri: 'http://example.org/') }.to raise_error(ArgumentError)
        end
      end

      context "resolving local-name only, or prefix:local-name strings" do
        specify "local-name only strings require no supporting prefix/uri bindings" do
          expect(QName.resolve('name')).to eq(QName.create(local_name: 'name'))
        end

        specify "local-name only qnames can also be represented by Symbolss" do
          expect(QName.resolve(:name)).to eq(QName.create(local_name: 'name'))
        end

        specify "prefix:local-name strings require a prefix/uri binding" do
          expect(QName.resolve('prefix:name', {'prefix' => 'http://example.org/#ns'})).
            to eq(QName.create(prefix: 'prefix', local_name: 'name', uri: 'http://example.org/#ns'))
        end

        specify "prefix:local-name strings without a binding for the prefix raise an error" do
          expect { QName.resolve('prefix:name') }.to raise_error(QName::PrefixedStringWithoutNSURIError)
        end

        specify "instances are passed through" do
          qname = QName.clark('name')
          expect(QName.resolve(qname)).to be(qname)
        end

        specify "instances of the underlying Java S9 API QName are wrapped" do
          qname = QName.clark('name')
          expect(QName.resolve(qname.to_java)).to eq(qname)
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

      specify "return their XPath lexical form for #to_s" do
        expect(subject.to_s).to eq('pre:el')
      end

      context "comparison" do
        specify "two QNames with the same NS URI and name are equal, prefix is ignored" do
          expect(subject).to eq(Saxon::QName.clark("{http://example.org/}el"))
        end

        specify "two QNames with the same NS URI and name generate the same hash code, prefix is ignored" do
          expect(subject.hash).to eq(Saxon::QName.clark("{http://example.org/}el").hash)
        end
      end
    end
  end
end
