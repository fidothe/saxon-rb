require_relative '../xdm_node'

module Saxon
  module XPath
    # Represents a compiled XPath query ready to be executed
    class Executable
      # @api private
      # @param s9_xpath_executable [net.sf.saxon.s9api.XPathExecutable] the
      #   Saxon compiled XPath object
      def initialize(s9_xpath_executable)
        @s9_xpath_executable = s9_xpath_executable
      end

      # Run the compiled query using a passed-in node as the context item.
      # @param context_item [Saxon::XdmNode] the context item node
      # @return [Saxon::XPath::Result] the result of the query as an
      #   enumerable
      def run(context_item)
        selector = to_java.load
        selector.setContextItem(context_item.to_java)
        Result.new(selector.iterator)
      end

      # @return [net.sf.saxon.s9api.XPathExecutable] the underlying Saxon
      #   <tt>XPathExecutable</tt>
      def to_java
        @s9_xpath_executable
      end
    end

    # The result of executing an XPath query as an enumerable object
    class Result
      include Enumerable

      # @api private
      # @param result_iterator [java.util.Iterator] the result of calling
      #   <tt>#iterator</tt> on a Saxon <tt>XPathSelector</tt>
      def initialize(result_iterator)
        @result_iterator = result_iterator
      end

      # Yields <tt>XdmNode</tt>s from the query result. If no block is passed,
      # returns an <tt>Enumerator</tt> 
      # @yieldparam xdm_node [Saxon::XdmNode] the name that is yielded
      def each(&block)
        @result_iterator.lazy.map { |s9_xdm_node| Saxon::XdmNode.new(s9_xdm_node) }.each(&block)
      end
    end
  end
end
