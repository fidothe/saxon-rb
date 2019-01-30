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
  end
end
