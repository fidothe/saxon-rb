require 'saxon'

RSpec.describe Saxon do
  describe "convenience methods" do
    specify "An XML document can be parsed into a Document node" do
      expect(Saxon::XML('<doc/>')).to be_a(Saxon::XDM::Node)
    end
  end
end