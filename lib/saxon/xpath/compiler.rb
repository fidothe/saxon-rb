require 'forwardable'
require_relative './static_context'
require_relative './executable'

module Saxon
  module XPath
    # An {XPath::Compiler} turns XPath expressions into executable queries you
    # can run against XDM Nodes (like XML documents, or parts of XML documents).
    #
    # To compile an XPath requires an +XPath::Compiler+ instance. You can create
    # one by calling {Compiler.create} and passing a {Saxon::Processor}, with an
    # optional block for context like bound namespaces and declared variables.
    # Alternately, and much more easily, you can call {Processor#xpath_compiler}
    # on the {Saxon::Processor} instance you're already working with.
    #
    #     processor = Saxon::Processor.create
    #     compiler = processor.xpath_compiler {
    #       namespace a: 'http://example.org/a'
    #       variable 'a:var', 'xs:string'
    #     }
    #     # Or...
    #     compiler = Saxon::XPath::Compiler.create(processor) {
    #       namespace a: 'http://example.org/a'
    #       variable 'a:var', 'xs:string'
    #     }
    #     xpath = compiler.compile('//a:element[@attr = $a:var]')
    #     matches = xpath.evaluate(document_node, {
    #       'a:var' => 'the value'
    #     }) #=> Saxon::XDM::Value
    #
    # In order to use prefixed QNames in your XPaths, like +/ns:name/+, then you need
    # to declare prefix/namespace URI bindings when you create a compiler.
    #
    # It's also possible to make use of variables in your XPaths by declaring them at
    # the compiler creation stage, and then passing in values for them as XPath run
    # time.
    class Compiler
      # Create a new <tt>XPath::Compiler</tt> using the supplied Processor.
      # Passing a block gives access to a DSL for setting up the compiler's
      # static context.
      #
      # @param processor [Saxon::Processor] the {Saxon::Processor} to use
      # @yield An XPath compiler DSL block
      # @return [Saxon::XPath::Compiler] the new compiler instance
      def self.create(processor, &block)
        static_context = XPath::StaticContext.define(block)
        new(processor.to_java, static_context)
      end

      extend Forwardable

      attr_reader :static_context
      private :static_context

      # @api private
      # @param s9_processor [net.sf.saxon.s9api.Processor] the Saxon
      #   <tt>Processor</tt> to wrap
      # @param static_context [Saxon::XPath::StaticContext] the static context
      #   XPaths compiled using this compiler will have
      def initialize(s9_processor, static_context)
        @s9_processor, @static_context = s9_processor, static_context
      end

      def_delegators :static_context, :default_collation, :declared_namespaces, :declared_variables
      # @!attribute [r] default_collation
      #   @return [String] the URI of the default declared collation
      # @!attribute [r] declared_namespaces
      #   @return [Hash<String => String>] declared namespaces as prefix => URI hash
      # @!attribute [r] declared_variables
      #   @return [Hash<Saxon::QName => Saxon::XPath::VariableDeclaration>] declared variables as QName => Declaration hash

      # @param expression [String] the XPath expression to compile
      # @return [Saxon::XPath::Executable] the executable query
      def compile(expression)
        Saxon::XPath::Executable.new(new_compiler.compile(expression), static_context)
      end

      # Allows the creation of a new {Compiler} starting from a copy of this
      # Compiler's static context. As with {.create}, passing a block gives
      # access to a DSL for setting up the compiler's static context.
      #
      # @yield An {XPath::StaticContext::DSL} block
      # @return [Saxon::XPath::Compiler] the new compiler instance
      def create(&block)
        new_static_context = static_context.define(block)
        self.class.new(@s9_processor, new_static_context)
      end

      private

      def new_compiler
        compiler = @s9_processor.newXPathCompiler
        declared_namespaces.each do |prefix, uri|
          compiler.declareNamespace(prefix, uri)
        end
        declared_variables.each do |_, decl|
          compiler.declareVariable(*decl.compiler_args)
        end
        compiler.declareDefaultCollation(default_collation) unless default_collation.nil?
        compiler
      end
    end
  end
end
