require_relative './executable'

module Saxon
  module XPath
    # Compiles XPath expressions so they can be executed
    class Compiler
      # @api private
      # @param s9_xpath_compiler [net.sf.saxon.s9api.XPathCompiler] the Saxon
      #   <tt>XPathCompiler</tt> to wrap
      def initialize(s9_xpath_compiler)
        @s9_xpath_compiler = s9_xpath_compiler
      end

      # @param expression [String] the XPath expression to compile
      # @return [Saxon::XPath::Executable] the executable query
      def compile(expression)
        Saxon::XPath::Executable.new(to_java.compile(expression))
      end

      # @return [net.sf.saxon.s9api.XPathCompiler] the underlying Java Saxon
      #   <tt>XPathCompiler</tt> instance
      def to_java
        @s9_xpath_compiler
      end
    end
  end
end
