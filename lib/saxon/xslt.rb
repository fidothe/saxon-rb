require_relative './xslt/compiler'

module Saxon
  # Classes for compiling, configuring, and executing XSLT transformations
  # against XDM nodes or documents
  #
  # Using XSLT involves creating a compiler, compiling an XSLT file into an
  # executable, and then invoking that executable through applying templates
  # against an XML document, calling a named template, or calling a named
  # function.
  #
  # The easiest way to create an {XSLT::Compiler} instance is by using the
  # {Saxon::Processor#xslt_compiler} method.
  #
  # @see Saxon::XSLT::Compiler
  # @see Saxon::XSLT::Executable
  # @see Saxon::Processor#xslt_compiler
  module XSLT
  end
end
