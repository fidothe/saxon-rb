require 'saxon/version/library'

module Saxon
  RSpec.describe Version::Library do
    context "the currently loaded version" do
      subject { described_class.loaded_version }

      specify "returns the correct version string" do
        expect(subject.version).to eq(Java::net.sf.saxon.Version.getProductVersion)
      end

      specify "returns the correct edition" do
        expect(subject.edition).to eq(:he)
      end

      specify "returns the correct version components" do
        expect(subject.components).to eq(subject.version.split('.').map { |n| Integer(n, 10) })
      end

      specify "returns the string version for #to_s" do
        expect(subject.to_s).to eq(subject.version.to_s)
      end
    end

    context "another version" do
      subject { described_class.new("10.0", "EE") }

      specify "returns the correct version string" do
        expect(subject.version).to eq("10.0")
      end

      specify "returns the correct edition" do
        expect(subject.edition).to eq(:ee)
      end

      specify "returns the correct version components" do
        expect(subject.components).to eq([10, 0])
      end
    end

    describe "comparing versions" do
      let(:v9_9_1_7) { described_class.new("9.9.1.7", "HE") }
      let(:v9_10_0_0) { described_class.new("9.10.0.0", "HE") }
      let(:v9_9_1_6) { described_class.new("9.9.1.6", "HE") }
      let(:v10_0) { described_class.new("10.0", "HE") }

      context "greater-than" do
        specify "10.0 > 9.9" do
          expect(v10_0 > v9_9_1_7).to be(true)
        end

        specify "9.10.0.0 > 9.9.1.7" do
          expect(v9_10_0_0 > v9_9_1_7).to be(true)
        end
      end

      context "less-than" do
        specify "9.9.1.6 < 9.9.1.7" do
          expect(v9_9_1_6 < v9_9_1_7).to be(true)
        end
      end

      context "greater-than-or-equal-to" do
        specify "9.9.1.7 >= 9.9.1.7" do
          expect(v9_9_1_7 >= v9_9_1_7).to be(true)
        end

        specify "10.0 >= 9.9.1.7" do
          expect(v10_0 >= v9_9_1_7).to be(true)
        end
      end

      context "less-than-or-equal-to" do
        specify "9.9.1.7 <= 9.9.1.7" do
          expect(v9_9_1_7 <= v9_9_1_7).to be(true)
        end

        specify "9.9.1.7 <= 10" do
          expect(v9_9_1_7 <= v10_0).to be(true)
        end
      end

      context "equal" do
        specify "9.9.1.7 == 9.9.1.7" do
          expect(v9_9_1_7 == v9_9_1_7).to be(true)
        end

        specify "9.9.1.6 != 9.9.1.7" do
          expect(v9_9_1_6 != v9_9_1_7).to be(true)
        end
      end

      context "~> pessimistic version comparison" do
        let(:v8_9_0_0) { described_class.new("8.9.0.0", "HE") }
        let(:v9_8_0_0) { described_class.new("9.8.0.0", "HE") }
        let(:v9_9_0_0) { described_class.new("9.9.0.0", "HE") }
        let(:v9_9_1_0) { described_class.new("9.9.1.0", "HE") }
        let(:v9_9_1) { described_class.new("9.9.1", "HE") }
        let(:v9_9) { described_class.new("9.9", "HE") }
        let(:v9_0) { described_class.new("9.0", "HE") }
        let(:v9_9_2_0) { described_class.new("9.9.2.0", "HE") }

        context "passes" do
          specify "9.9.1.6 ~> 9.9.1.0" do
            expect(v9_9_1_6.pessimistic_compare(v9_9_1_0)).to be(true)
          end

          specify "9.9.1.6 ~> 9.9.1.6" do
            expect(v9_9_1_6.pessimistic_compare(v9_9_1_6)).to be(true)
          end

          specify "9.9.1.6 ~> 9.9.1" do
            expect(v9_9_1_6.pessimistic_compare(v9_9_1)).to be(true)
          end

          specify "9.9.2.0 ~> 9.9.1" do
            expect(v9_9_2_0.pessimistic_compare(v9_9_1)).to be(true)
          end

          specify "9.9.1.6 ~> 9.9" do
            expect(v9_9_1_6.pessimistic_compare(v9_9)).to be(true)
          end

          specify "9.10.0.0 ~> 9.9" do
            expect(v9_10_0_0.pessimistic_compare(v9_9)).to be(true)
          end

          specify "9.9.1.6 ~> 9" do
            expect(v9_9_1_6.pessimistic_compare(v9_0)).to be(true)
          end

        end

        context "fails" do
          specify "9.9.2.0 ~> 9.9.1.0" do
            expect(v9_9_2_0.pessimistic_compare(v9_9_1_0)).to be(false)
          end

          specify "9.9.1.6 ~> 9.9.1.7" do
            expect(v9_9_1_6.pessimistic_compare(v9_9_1_7)).to be(false)
          end

          specify "9.9.0.0 ~> 9.9.1" do
            expect(v9_9_0_0.pessimistic_compare(v9_9_1)).to be(false)
          end

          specify "9.10.0.0 ~> 9.9.1" do
            expect(v9_10_0_0.pessimistic_compare(v9_9_1)).to be(false)
          end

          specify "9.8 ~> 9.9" do
            expect(v9_8_0_0.pessimistic_compare(v9_9)).to be(false)
          end

          specify "10.0 ~> 9.9" do
            expect(v10_0.pessimistic_compare(v9_9)).to be(false)
          end

          specify "8.9.0.0 ~> 9" do
            expect(v8_9_0_0.pessimistic_compare(v9_0)).to be(false)
          end

          specify "10.0 ~> 9" do
            expect(v10_0.pessimistic_compare(v9_0)).to be(false)
          end
        end
      end
    end
  end
end