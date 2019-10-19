require 'saxon/processor'
require 'saxon/source'
require 'saxon/qname'
require 'saxon/axis_iterator'

RSpec.describe Saxon::AxisIterator do
  let(:doc_builder) { Saxon::Processor.create.document_builder }
  let(:source) { Saxon::Source.from_string(%{<doc xmlns:a="http://example.org/" a="1"><c1><g1/></c1><c2><g2/></c2></doc>}) }
  let(:xdm_node) { doc_builder.build(source) }
  let(:root_element) { Saxon::AxisIterator.new(xdm_node, :child).first }
  let(:c1_element) { Saxon::AxisIterator.new(root_element, :child).first }
  let(:c2_element) { Saxon::AxisIterator.new(root_element, :child).to_a.last }

  describe "instances" do
    subject { Saxon::AxisIterator.new(xdm_node, :child) }

    specify "yield Saxon::XDM::Nodes" do
      expect(subject.each.first).to be_a(Saxon::XDM::Node)
    end

    specify "can return an Array" do
      expect(subject.to_a).to eq([root_element])
    end

    specify "can be re-iterated over" do
      expect(subject.map { |n| n }).to eq(subject.map { |n| n })
    end
  end

  describe "mapping axis symbols correctly for" do
    specify "child" do
      iterator = Saxon::AxisIterator.new(xdm_node, :child)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("doc")])
    end

    specify "self" do
      iterator = Saxon::AxisIterator.new(root_element, :self)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("doc")])
    end

    specify "attribute" do
      iterator = Saxon::AxisIterator.new(root_element, :attribute)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("a")])
    end

    specify "parent" do
      iterator = Saxon::AxisIterator.new(c1_element, :parent)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("doc")])
    end

    specify "ancestor" do
      iterator = Saxon::AxisIterator.new(c1_element, :ancestor)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("doc"), nil])
    end

    specify "ancestor-or-self" do
      iterator = Saxon::AxisIterator.new(c1_element, :ancestor_or_self)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([Saxon::QName.clark("c1"), Saxon::QName.clark("doc"), nil])
    end

    specify "descendant" do
      iterator = Saxon::AxisIterator.new(xdm_node, :descendant)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        Saxon::QName.clark("doc"), Saxon::QName.clark("c1"), Saxon::QName.clark("g1"), Saxon::QName.clark("c2"), Saxon::QName.clark("g2")
      ])
    end

    specify "descendant-or-self" do
      iterator = Saxon::AxisIterator.new(xdm_node, :descendant_or_self)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        nil, Saxon::QName.clark("doc"), Saxon::QName.clark("c1"), Saxon::QName.clark("g1"), Saxon::QName.clark("c2"), Saxon::QName.clark("g2")
      ])
    end

    specify "following" do
      iterator = Saxon::AxisIterator.new(c1_element, :following)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        Saxon::QName.clark("c2"), Saxon::QName.clark("g2")
      ])
    end

    specify "following-sibling" do
      iterator = Saxon::AxisIterator.new(c1_element, :following_sibling)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        Saxon::QName.clark("c2")
      ])
    end

    specify "preceding" do
      iterator = Saxon::AxisIterator.new(c2_element, :preceding)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        Saxon::QName.clark("g1"), Saxon::QName.clark("c1")
      ])
    end

    specify "preceding-sibling" do
      iterator = Saxon::AxisIterator.new(c2_element, :preceding_sibling)

      expect(iterator.map { |xdm_node| xdm_node.node_name }).to eq([
        Saxon::QName.clark("c1")
      ])
    end
  end
end
