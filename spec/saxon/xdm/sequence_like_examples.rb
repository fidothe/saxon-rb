RSpec.shared_examples "an XDM Value hierarchy sequence-like" do
  context "sequence enumeration" do
    specify "returns an enumerable for #sequence_enum" do
      expect(subject.sequence_enum).to respond_to(:each)
    end

    specify "returns the size of the sequence" do
      expect(subject.sequence_size).to eq(subject.sequence_enum.to_a.size)
    end
  end

  context "sequnce appending" do
    specify "appending itself produces a value with twice as many things in" do
      old_size = subject.sequence_size
      appended = subject.append(subject)

      expect(appended).to be_a(Saxon::XDM::Value)
      expect(appended.sequence_size).to eq(old_size * 2)
    end

    specify "values are immutable so appending does not mutate them" do
      old_size = subject.sequence_size
      appended = subject.append(subject)

      expect(appended).to_not eq(subject)
      expect(subject.sequence_size).to eq(old_size)
    end

    specify "appending also works via #<<" do
      appended = subject << subject

      expect(appended.sequence_size).to eq(subject.sequence_size * 2)
    end

    specify "appending also works with #+" do
      appended = subject + subject

      expect(appended.size).to eq(subject.sequence_size * 2)
    end

    context "appending regular Ruby objects" do
      specify "causes them to be wrapped as an AtomicValue" do
        new_value = subject << 1

        expect(new_value.sequence_enum.to_a.last).to eq(Saxon::XDM::AtomicValue.create(1))
      end

      specify "using an array causes them to be wrapped but doesn't create an XDM::Array" do
        new_value = subject << [1, 2]

        expect(new_value.sequence_enum.to_a.reverse[0..1]).to eq([
          Saxon::XDM::AtomicValue.create(2),
          Saxon::XDM::AtomicValue.create(1)
        ])
      end
    end
  end
end