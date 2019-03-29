require 'saxon/processor'
require 'saxon/source'
require 'saxon/xpath/compiler'

RSpec.describe Saxon::XPath::Compiler do
  let(:processor) { Saxon::Processor.create }
  let(:context_xml) {
<<-EOS
<doc>
  <collation>
    <e a="1">aä</e>
    <e a="2">ab</e>
  </collation>
  <namespace>
    <a:n xmlns:a="http://example.org/a"/>
  </namespace>
</doc>
EOS
  }
  let(:source) { Saxon::Source.from_string(context_xml, base_uri: "http://example.org/") }
  let(:context_doc) { processor.document_builder.build(source) }

  it "is instantiated from a Processor factory method" do
    expect(processor.xpath_compiler).to be_a(Saxon::XPath::Compiler)
  end

  describe "producing a compiler" do
    context "without data in the static context" do
      it "can be produced simply from a Saxon::Processor" do
        expect(Saxon::XPath::Compiler.create(processor)).to be_a(Saxon::XPath::Compiler)
      end
    end

    context "collations" do
      it "can have collations and default collation set" do
        us_collation = java.text.Collator.getInstance(java.util.Locale::US)
        uk_collation = java.text.Collator.getInstance(java.util.Locale::UK)
        compiler = Saxon::XPath::Compiler.create(processor) {
          collation 'http://example.org/collation' => us_collation
          collation 'http://example.org/collation-1' => uk_collation
          default_collation 'http://example.org/collation'
        }

        expect(compiler.declared_collations).to eq({
          'http://example.org/collation' => us_collation, 'http://example.org/collation-1' => uk_collation
        })
        expect(compiler.default_collation).to eq('http://example.org/collation')
      end
    end

    context "namespaces" do
      it "can have namespaces bound to prefixes" do
        compiler = Saxon::XPath::Compiler.create(processor) {
          namespace a: 'http://example.org/a', b: 'http://example.org/b'
          namespace 'c' => 'http://example.org/c'
        }

        expect(compiler.declared_namespaces).to eq({
          'a' => 'http://example.org/a', 'b' => 'http://example.org/b',
          'c' => 'http://example.org/c'
        })
      end
    end

    context "variables" do
      let(:qname) {
        Saxon::QName.create({
          prefix: 'a', uri: 'http://example.org/a', local_name: 'var'
        })
      }

      it "can be declared without explicit type info" do
        compiler = Saxon::XPath::Compiler.create(processor) {
          namespace a: 'http://example.org/a'
          variable 'a:var'
        }

        expect(compiler.declared_variables).to eq({
          qname => Saxon::XPath::VariableDeclaration.new({
            qname: qname,
            zero_or_more: 'item()'
          })
        })
      end

      it "can be declared with a Ruby type mapped to an XDM type" do
        compiler = Saxon::XPath::Compiler.create(processor) {
          namespace a: 'http://example.org/a'
          variable 'a:var', one_or_more: ::String
        }

        expect(compiler.declared_variables).to eq({
          qname => Saxon::XPath::VariableDeclaration.new({
            qname: qname,
            one_or_more: 'xs:string'
          })
        })
      end

      it "can be declared with explicit type / occurence info" do
        compiler = Saxon::XPath::Compiler.create(processor) {
          namespace a: 'http://example.org/a'
          variable 'a:var', 'xs:string+'
        }

        expect(compiler.declared_variables).to eq({
          qname => Saxon::XPath::VariableDeclaration.new({
            qname: qname,
            one_or_more: 'xs:string'
          })
        })
      end

      it "can be declared with a variable name not in a namespace" do
        qname = Saxon::QName.clark('var')
        compiler = Saxon::XPath::Compiler.create(processor) {
          variable 'var'
        }

        expect(compiler.declared_variables).to eq({
          qname => Saxon::XPath::VariableDeclaration.new({
            qname: qname,
            zero_or_more: 'item()'
          })
        })
      end

      it "cannot be declared if a needed namespace binding isn't there" do
        expect {
          Saxon::XPath::Compiler.create(processor) { variable 'a:var' }
        }.to raise_error(Saxon::XPath::MissingVariableNamespaceError)
      end
    end

    context "immutability" do
      subject {
        described_class.create(processor) {
          namespace a: 'http://example.org/a'
          variable 'a:var', 'xs:string'
          collation 'http://example.org/collation' => java.text.Collator.getInstance(java.util.Locale::UK)
          default_collation 'http://example.org/collation'
        }
      }

      specify "the declared_variables hash is frozen" do
        expect { subject.declared_variables['a'] = :a }.to raise_error(FrozenError)
      end

      specify "the default collation cannot be changed" do

      end

      specify "the declared_collations hash is frozen"
      specify "the declared_namespaces hash is frozen"
    end

    context "deriving a new Compiler from an existing one" do
      let(:uk_collation) { java.text.Collator.getInstance(java.util.Locale::UK) }
      let(:us_collation) { java.text.Collator.getInstance(java.util.Locale::US) }
      let(:base) {
        ukc = uk_collation
        described_class.create(processor) {
          namespace a: 'http://example.org/a'
          variable 'a:var', 'xs:string'
          collation 'http://example.org/collation' => ukc
          default_collation 'http://example.org/collation'
        }
      }

      specify "the existing properties are preserved" do
        usc = us_collation
        compiler = base.create {
          namespace b: 'http://example.org/b'
          variable 'b:var', 'xs:string'
          collation 'http://example.org/collation-1' => usc
        }

        expect(compiler.declared_namespaces).to eq({
          'a' => 'http://example.org/a', 'b' => 'http://example.org/b'
        })

        a_var_qname = Saxon::QName.create({
          prefix: 'a', uri: 'http://example.org/a', local_name: 'var'
        })
        b_var_qname = Saxon::QName.create({
          prefix: 'b', uri: 'http://example.org/b', local_name: 'var'
        })
        expect(compiler.declared_variables).to eq({
          a_var_qname => Saxon::XPath::VariableDeclaration.new(qname: a_var_qname, one: 'xs:string'),
          b_var_qname => Saxon::XPath::VariableDeclaration.new(qname: b_var_qname, one: 'xs:string')
        })

        expect(compiler.declared_collations).to eq({
          'http://example.org/collation' => uk_collation, 'http://example.org/collation-1' => us_collation
        })
        expect(compiler.default_collation).to eq('http://example.org/collation')
      end

      specify "existing properties can be overwritten" do
        usc = us_collation
        compiler = base.create {
          variable 'a:var', 'xs:string+'
          default_collation nil
        }

        expect(compiler.declared_namespaces).to eq({
          'a' => 'http://example.org/a'
        })

        a_var_qname = Saxon::QName.create({
          prefix: 'a', uri: 'http://example.org/a', local_name: 'var'
        })
        expect(compiler.declared_variables).to eq({
          a_var_qname => Saxon::XPath::VariableDeclaration.new(qname: a_var_qname, one_or_more: 'xs:string')
        })

        expect(compiler.default_collation).to be_nil
      end
    end
  end

  describe "compiling and running an XPath" do
    specify "a simple XPath with no context" do
      compiler = described_class.create(processor)
      expect(compiler.compile('/doc').run(context_doc).to_a).
        to eq(context_doc.axis_iterator(:child).to_a)
    end

    specify "an XPath which makes use of collations" do
      german = java.text.Collator.getInstance(java.util.Locale.new('de', 'DE'))
      compiler = described_class.create(processor) {
        collation 'http://example.org/german' => german
        default_collation 'http://example.org/german'
      }
      expect(compiler.compile('/doc/collation/e[1][compare(., /doc/collation/e[2]) = 1]').run(context_doc).to_a).to eq([])
    end

    specify "an XPath which uses namespaces" do
      compiler = described_class.create(processor) {
        namespace a: 'http://example.org/a'
      }
      expect(compiler.compile('/doc/namespace/a:n').run(context_doc).to_a.size).to eq(1)
    end

    specify "an XPath which uses variables" do
      compiler = described_class.create(processor) {
        variable 'var', 'xs:string'
      }
      expect(compiler.compile('/doc/collation/e[. = $var]').run(context_doc, 'var' => 'ab').to_a.size).to eq(1)
    end
  end
end
