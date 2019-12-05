require 'saxon/occurrence_indicator'

module Saxon
  RSpec.describe OccurrenceIndicator do
    specify "can return a list of all allowable indicator names" do
      expect(OccurrenceIndicator.indicator_names.sort).to eq([:one, :one_or_more, :zero, :zero_or_more, :zero_or_one])
    end

    context "being conveniently returned" do
      specify "from a symbol" do
        expect(OccurrenceIndicator.get_indicator(:one)).to be(OccurrenceIndicator.one)
      end

      specify "passes through an OccurrenceIndicator" do
        expect(OccurrenceIndicator.get_indicator(OccurrenceIndicator.one)).to be(OccurrenceIndicator.one)
      end

      specify "an invalid symbol raises an error" do
        expect { OccurrenceIndicator.get_indicator(:tons) }.to raise_error(ArgumentError)
      end
    end
  end
end