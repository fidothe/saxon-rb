require 'saxon/xdm'
require_relative 'sequence_like_examples'

module Saxon
  RSpec.describe XDM::Map do
    context "creation" do
      context "from a Ruby Hash" do
        specify "a hash of simple values gets correctly created" do
          hash = {'a' => 1, 'b' => 2}
          map = described_class.create(hash)

          expect(map.to_java.asImmutableMap.to_hash).to eq({
            S9API::XdmAtomicValue.new('a') => S9API::XdmAtomicValue.new(1),
            S9API::XdmAtomicValue.new('b') => S9API::XdmAtomicValue.new(2)
          })
        end

        specify "a hash of arrays becomes a map of XDM Values" do
          hash = {'a' => [1, 2], 'b' => [3, 4]}
          map = described_class.create(hash)

          expect(map.to_h).to eq({
            XDM.AtomicValue('a') => XDM::Value.create(1, 2),
            XDM.AtomicValue('b') => XDM::Value.create(3, 4)
          })
        end
      end
    end

    context "instances" do
      subject {
        described_class.new(S9API::XdmMap.new({
          S9API::XdmAtomicValue.new('a') => S9API::XdmAtomicValue.new(1)
        }))
      }

      context "accessing members using #[]" do
        specify "works with an XDM::AtomicValue" do
          expect(subject[XDM.AtomicValue('a')]).to eq(XDM.AtomicValue(1))
        end

        specify "works with a Ruby value" do
          expect(subject['a']).to eq(XDM.AtomicValue(1))
        end

        specify "works with an s9api.XdmAtomicValue" do
          expect(subject[XDM.AtomicValue('a').to_java]).to eq(XDM.AtomicValue(1))
        end
      end

      context "comparison" do
        specify "two maps compare equal if they have the same keys and values" do
          map_1 = XDM::Map.create('a' => 1, 'b' => 2)
          map_2 = XDM::Map.create('a' => 1, 'b' => 2)

          expect(map_1).to eq(map_2)
        end
      end

      specify "can be iterated across like Ruby hashes" do
        akku = []
        subject.each do |k, v|
          akku << [k, v]
        end

        expect(akku).to eq([
          [XDM.AtomicValue('a'), XDM.AtomicValue(1)]
        ])
      end

      context "can be merged with another instance to create a new instance" do
        let(:map_1) { XDM::Map.create('a' => 1, 'b' => 2) }
        let(:map_2) { XDM::Map.create('c' => 3, 'd' => 4) }

        specify "which contains all items from both the prior instances" do
          expect(map_1.merge(map_2)).to eq(XDM::Map.create('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4))
        end

        specify "in the process which neither prior instances are mutated" do
          map_3 = map_1.merge(map_2)
          expect(map_1).to eq(XDM::Map.create('a' => 1, 'b' => 2))
          expect(map_2).to eq(XDM::Map.create('c' => 3, 'd' => 4))
        end
      end

      context "enumerable methods that would return a new hash in Ruby" do
        subject {
          XDM::Map.create({'a' => 1, 'b' => 2})
        }

        specify "#select returns a new Map" do
          expect(subject.select { |k, v| k == XDM.AtomicValue('a') }).to eq(XDM::Map.create({'a' => 1}))
        end

        specify "#reject returns a new Map" do
          expect(subject.reject { |k, v| k == XDM.AtomicValue('a') }).to eq(XDM::Map.create({'b' => 2}))
        end
      end

      it_should_behave_like "an XDM Value hierarchy sequence-like"
      it_should_behave_like "an XDM Item hierarchy sequence-like"
    end
  end
end
