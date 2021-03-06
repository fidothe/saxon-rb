require_relative 'saxon/version'
require_relative 'saxon/processor'

# An idiomatic Ruby wrapper around the Saxon XML processing library.
module Saxon
  # Parse an XML document using a vanilla {DocumentBuilder} from the default
  # {Processor}
  # @see Saxon::Processor#XML
  def self.XML(input, opts = {})
    Processor.default.XML(input, opts)
  end

  # Compile an XSLT Stylesheet using a new {XSLT::Compiler} from the default
  # {Processor}
  # @see Saxon::Processor#XSLT
  def self.XSLT(input, opts = {}, &block)
    Processor.default.XSLT(input, opts, &block)
  end
end
