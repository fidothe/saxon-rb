require_relative '../xdm'

module Saxon
  module XPath
    # Represents a compiled XPath query ready to be executed. An
    # {XPath::Executable} is created by compiling an XPath expression with
    # {XPath::Compiler#compile}.
    #
    # To run the +XPath::Executable+ you can call {XPath::Executable#evaluate},
    # to generate an {XDM::Value} of the results, or you can call
    # {XPath::Executable#as_enum} to return an Enumerator over the results.
    #
    #     processor = Saxon::Processor.create
    #     compiler = processor.xpath_compiler
    #     xpath = compiler.compile('//element[@attr = $var]')
    #
    #     matches = xpath.evaluate(document_node, {'var' => 'the value'}) #=> Saxon::XDM::Value
    #
    #     xpath.as_enum(document_node, {'var' => 'the value'}).each do |node|
    #       ...
    #     end
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


      # Evaluate the XPath against the context node given and return an
      # +Enumerator+ over the result.
      #
      # @param context_item [Saxon::XDM::Node, Saxon::XDM::AtomicValue] the item
      #   to be used as the context item for evaluating the XPath from.
      # @param variables [Hash<Saxon::QName => Saxon::XDM::Value, Saxon::XDM::Node,
      #   Saxon::XDM::AtomicValue>] any variable values to set within the XPath
      # @return [Enumerator] an Enumerator over the items in the result sequence
      def as_enum(context_item, variables = {})
        generate_selector(context_item, variables).iterator.lazy.
          map { |s9_xdm_object| Saxon::XDM.Value(s9_xdm_object) }
      end

      # Evaluate the XPath against the context node given and return the result.
      #
      # If the result is a single item, then that will be returned directly
      # (e.g. an {XDM::Node} or an {XDM::AtomicValue}). If the result is an
      # empty sequence then {XDM::EmptySequence} is returned.
      #
      # @param context_item [Saxon::XDM::Node, Saxon::XDM::AtomicValue] the item
      #   to be used as the context item for evaluating the XPath from.
      # @param variables [Hash<Saxon::QName => Saxon::XDM::Value, Saxon::XDM::Node,
      #   Saxon::XDM::AtomicValue>] any variable values to set within the XPath
      # @return [Saxon::XDM::Value] the XDM value returned
      def evaluate(context_item, variables = {})
        s9_xdm_value = generate_selector(context_item, variables).evaluate
        Saxon::XDM.Value(s9_xdm_value)
      end

      # @return [net.sf.saxon.s9api.XPathExecutable] the underlying Saxon
      #   <tt>XPathExecutable</tt>
      def to_java
        @s9_xpath_executable
      end

      private

      def generate_selector(context_item, variables = {})
        selector = to_java.load
        selector.setContextItem(context_item.to_java)
        variables.each do |qname_or_string, value|
          selector.setVariable(static_context.resolve_variable_qname(qname_or_string).to_java, Saxon::XDM.Value(value).to_java)
        end
        selector
      end
    end
  end
end
