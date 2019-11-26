require 'saxon'

RSpec.describe Saxon do
  describe "convenience methods" do
    specify "An XML document can be parsed into a Document node" do
      expect(Saxon::XML('<doc/>')).to be_a(Saxon::XDM::Node)
    end

    specify "An XSLT stylesheet can be parsed into an XSLT::Executable" do
      expect(Saxon::XSLT(fixture_path('eg.xsl'))).to be_a(Saxon::XSLT::Executable)
    end
  end
end