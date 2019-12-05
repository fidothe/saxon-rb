require 'saxon/xpath/variable_declaration'
require 'saxon/qname'

RSpec.describe Saxon::XPath::VariableDeclaration do
  let(:qname) { Saxon::QName.clark("{http://example.org/}test") }
  let(:sequence_type) { Saxon.SequenceType('xs:string') }
  subject { described_class.new(qname, sequence_type) }

  describe "instances" do
    it "return their qname" do
      expect(subject.qname).to eq(qname)
    end

    it "return their sequence type" do
      expect(subject.sequence_type).to be(sequence_type)
    end
  end

  describe "comparison" do
    specify "compares equal with another instance with the same qname, type, and occurence" do
      expect(subject).to eq(described_class.new(qname, sequence_type))
    end
  end
end
