require 'saxon/sequence_type'

module Saxon
  RSpec.describe SequenceType do
    context "instantiating" do
      let(:item_type) { Saxon::ItemType.get_type(::String) }
      let(:occurrence_indicator) { Saxon::OccurrenceIndicator.one }

      context "from ItemType and OccurrenceIndicator arguments" do
        subject { described_class.new(item_type, occurrence_indicator) }

        specify "can return its Saxon::ItemType" do
          expect(subject.item_type).to be(item_type)
        end

        specify "can return its Saxon::OccurrenceIndicator" do
          expect(subject.occurrence_indicator).to be(occurrence_indicator)
        end

        specify "can return an s9api.SequenceType" do
          expect(subject.to_java).to be_a(S9API::SequenceType)
          expect(subject.to_java.getItemType).to eq(item_type.to_java)
          expect(subject.to_java.getOccurrenceIndicator).to eq(occurrence_indicator.to_java)
        end
      end

      context "from an s9api.SequenceType" do
        let(:s9_sequence_type) {
          Saxon::S9API::SequenceType.make_sequence_type(item_type.to_java, occurrence_indicator.to_java)
        }
        subject { described_class.new(s9_sequence_type) }

        specify "can return a Saxon::ItemType" do
          expect(subject.item_type).to eq(item_type)
        end

        specify "can return a Saxon::OccurrenceIndicator" do
          expect(subject.occurrence_indicator).to eq(occurrence_indicator)
        end

        specify "can return the original s9api.SequenceType" do
          expect(subject.to_java).to be(s9_sequence_type)
        end
      end

      specify "failing to pass an S9 SequenceType when instantiating with a single arg raises an error" do
        expect { described_class.new(item_type) }.to raise_error(ArgumentError)
      end

      context "convenience creation" do
        let(:zero_or_more_strings) {
          described_class.new(item_type, OccurrenceIndicator.zero_or_more)
        }

        specify "using type-occurence strings (xs:string+) into SequenceType instances" do
          expect(described_class.from_type_decl('xs:string*')).to eq(zero_or_more_strings)
        end

        describe "using a type string/literal / occurence indicator pair" do
          specify "with a literal ruby class and symbol for occurrence indicator" do
            expect(described_class.create(::String, :zero_or_more)).to eq(zero_or_more_strings)
          end

          specify "with an item type name and symbol for occurrence indicator" do
            expect(described_class.create('xs:string', :zero_or_more)).to eq(zero_or_more_strings)
          end

          specify "with an ItemType and symbol" do
            expect(described_class.create(item_type, :zero_or_more)).to eq(zero_or_more_strings)
          end

          specify "with an ItemType and OccurrenceIndicator" do
            expect(described_class.create(item_type, OccurrenceIndicator.zero_or_more)).to eq(zero_or_more_strings)
          end

          specify "with an item type name and OccurrenceIndicator" do
            expect(described_class.create('xs:string', OccurrenceIndicator.zero_or_more)).to eq(zero_or_more_strings)
          end
        end

        specify ".create is exposed as Saxon.SequenceType()" do
          expect(Saxon.SequenceType('xs:string*')).to eq(zero_or_more_strings)
        end
      end
    end

    describe "instances" do
      context "comparison" do
        let(:s_type_1) { described_class.from_type_decl('xs:string+') }
        let(:s_type_2) { described_class.from_type_decl('xs:string+') }
        let(:s_type_3) { described_class.from_type_decl('xs:string*') }

        specify "two instances of the same ItemType and OccurrenceIndicator should compare equal" do
          expect(s_type_1).to eq(s_type_2)
        end

        specify "two instances with the same ItemType but different OccurrenceIndicator are not equal" do
          expect(s_type_1).not_to eq(s_type_3)
        end

        specify "two instances that compare equal also generate equal hash codes" do
          expect(s_type_1.hash).to eq(s_type_2.hash)
        end

        specify "two instances that do not compare equal shouldn't generate the same hash code" do
          expect(s_type_1.hash).not_to eq(s_type_3.hash)
        end
      end
    end
  end
end
