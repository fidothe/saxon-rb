require 'forwardable'
require_relative './static_context'
require_relative './executable'

module Saxon
  module XPath
    # Compiles XPath expressions so they can be executed
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
