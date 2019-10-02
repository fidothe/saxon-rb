require_relative '../xdm/node'
require_relative '../xdm/atomic_value'

module Saxon
  module XPath
    # Represents a compiled XPath query ready to be executed
    class Executable
      # @return [XPath::StaticContext] the XPath's static context
      attr_reader :static_context

      # @api private
      # @param s9_xpath_executable [net.sf.saxon.s9api.XPathExecutable] the
      #   Saxon compiled XPath object
      # @param static_context [XPath::StaticContext] the XPath's static
      #   context
      def initialize(s9_xpath_executable, static_context)
        @s9_xpath_executable, @static_context = s9_xpath_executable, static_context
      end

      # Run the compiled query using a passed-in node as the context item.
      # @param context_item [Saxon::XDM::Node] the context item node
      # @return [Saxon::XPath::Result] the result of the query as an
      #   enumerable
      def run(context_item, variables = {})
        selector = to_java.load
        selector.setContextItem(context_item.to_java)
        variables.each do |qname_or_string, value|
          selector.setVariable(static_context.resolve_variable_qname(qname_or_string).to_java, Saxon::XDM::AtomicValue.create(value).to_java)
        end
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

      # Yields <tt>XDM::Node</tt>s from the query result. If no block is passed,
      # returns an <tt>Enumerator</tt>
      # @yieldparam xdm_node [Saxon::XDM::Node] the name that is yielded
      def each(&block)
        @result_iterator.lazy.map { |s9_xdm_node| Saxon::XDM::Node.new(s9_xdm_node) }.each(&block)
      end
    end
  end
end
