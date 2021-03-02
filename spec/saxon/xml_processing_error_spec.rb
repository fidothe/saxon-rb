require 'java'
require 'saxon/xml_processing_error'

module Saxon
  RSpec.describe XMLProcessingError do
    context "wrapping a Java XmlProcessingIncident" do
      let(:underlying_incident) {
        Saxon::Loader.load!
        Java::net.sf.saxon.trans.XmlProcessingIncident.new('An incident', 'XPDY0002')
      }

      subject { described_class.new(underlying_incident) }

      specify "provides access to the message" do
        expect(subject.message).to eq('An incident')
      end

      specify "reports that it's not a warning" do
        expect(subject.warning?).to be(false)
      end

      specify "reports that it's not a fatal error" do
        expect(subject.fatal?).to be(false)
      end

      specify "reports that it's not a static error" do
        expect(subject.static_error?).to be(false)
      end

      specify "reports that it's not a type error" do
        expect(subject.type_error?).to be(false)
      end

      specify "provides access to the error code" do
        expect(subject.error_code).to eq(Saxon::QName.clark('{http://www.w3.org/2005/xqt-errors}XPDY0002'))
      end

      specify "provides the wrapped Java object" do
        expect(subject.to_java).to be(underlying_incident)
      end
    end


# HostLanguage
# getHostLanguage ()
# Location
# getLocation ()
# Get the location information associated with the error
# String
# getPath ()
# Get the absolute XPath expression that identifies the node within its document where the error occurred, if available
# XPathException
# getXPathException ()
# Get the wrapped exception
# boolean
# isAlreadyReported ()
# Ask whether this static error has already been reported
# void
# setAlreadyReported (boolean reported)
# Say whether this error has already been reported
# void
  end
end
