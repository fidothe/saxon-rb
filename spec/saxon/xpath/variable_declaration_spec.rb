require 'saxon/xpath/variable_declaration'
require 'saxon/qname'

RSpec.describe Saxon::XPath::VariableDeclaration do
  let(:qname) { Saxon::QName.clark("{http://example.org/}test") }

  describe "instantiating" do
    it "requires a QName" do
      decl = described_class.new(qname: qname)
      expect(decl).to be_a(Saxon::XPath::VariableDeclaration)
    end
  end

  describe "data" do
    subject { described_class.new(qname: qname, one: ::String) }

    it "returns its qname" do
      expect(subject.qname).to eq(qname)
    end

    it "returns its item type" do
      expect(subject.item_type).
        to eq(Saxon::ItemType.get_type('xs:string'))
    end

    it "returns its occurrences" do
      expect(subject.occurrences).to be(Saxon::OccurrenceIndicator.one)
    end
  end

  describe "comparison" do
    subject { described_class.new(qname: qname, one: ::String) }

    specify "compares equal with another instance with the same qname, type, and occurence" do
      expect(subject).to eq(described_class.new(qname: qname, one: 'xs:string'))
    end
  end
end
