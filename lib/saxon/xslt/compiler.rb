require 'forwardable'
require_relative './static_context'
# require_relative './executable'

module Saxon
  module XSLT
    # Compiles XSLT stylesheets so they can be executed
    class Compiler
      # Create a new <tt>XSLT::Compiler</tt> using the supplied Processor.
      # Passing a block gives access to a DSL for setting up the compiler's
      # static context.
      #
      # @param processor [Saxon::Processor] the {Saxon::Processor} to use
      # @yield An XSLT compiler DSL block
      # @return [Saxon::XSLT::Compiler] the new compiler instance
      def self.create(processor, &block)
        static_context = XSLT::StaticContext.define(block)
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

      def_delegators :static_context, :declared_collations, :default_collation
      # @!attribute [r] declared_collations
      #   @return [Hash<String => java.text.Collator>] declared collations as URI => Collator hash
      # @!attribute [r] default_collation
      #   @return [String] the URI of the default declared collation

      # @param expression [String] the  expression to compile
      # @return [Saxon::XSLT::Executable] the executable query
      def compile(expression)
        Saxon::XSLT::Executable.new(new_compiler.compile(expression), static_context)
      end

      def create(&block)
        new_static_context = static_context.define(block)
        self.class.new(@s9_processor, new_static_context)
      end

      private

      def new_compiler
        compiler = @s9_processor.newXsltCompiler
        declared_collations.each do |uri, collation|
          compiler.declareCollation(uri, collation)
        end
        compiler.declareDefaultCollation(default_collation) unless default_collation.nil?
        compiler
      end
    end
  end
end
