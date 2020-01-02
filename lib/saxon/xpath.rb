require_relative './xpath/compiler'

module Saxon
  # Classes for compiling, configuring, and executing XPath queries against
  # XDM nodes or documents
  #
  # Using an XPath involves creating a compiler, compiling an XPath into an
  # executable, and then running that XPath executable against an XDM node.
  #
  # The easiest way to create an XPath::Compiler instance is by using the {Saxon::Processor#xpath_compiler} method.
  #
  # @see Saxon::XPath::Compiler
  # @see Saxon::XPath::Executable
  # @see Saxon::Processor#xpath_compiler
  module XPath
  end
end
