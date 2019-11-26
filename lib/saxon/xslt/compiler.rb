require 'forwardable'
require_relative './evaluation_context'
require_relative './executable'

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
        evaluation_context = XSLT::EvaluationContext.define(block)
        new(processor.to_java, evaluation_context)
      end

      extend Forwardable

      attr_reader :evaluation_context
      private :evaluation_context

      # @api private
      # @param s9_processor [net.sf.saxon.s9api.Processor] the Saxon
      #   <tt>Processor</tt> to wrap
      # @param evaluation_context [Saxon::XSLT::EvaluationContext] the static context
      #   XPaths compiled using this compiler will have
      def initialize(s9_processor, evaluation_context)
        @s9_processor, @evaluation_context = s9_processor, evaluation_context
      end

      def_delegators :evaluation_context, :default_collation, :static_parameters, :global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters
      # @!attribute [r] declared_collations
      #   @return [Hash<String => java.text.Collator>] declared collations as URI => Collator hash
      # @!attribute [r] default_collation
      #   @return [String] the URI of the default declared collation
      # @!attribute [r] static_parameters
      #   @return [Hash<Saxon::QName => Saxon::XDM::Value, Saxon::XDM::Node,
      #   Saxon::XDM::AtomicValue>] parameters required at compile time as QName => value hash

      # @param source [Saxon::Source] the Source to compile
      # @yield the block is executed in the context of an {XSLT::EvaluationContext} DSL instance
      # @return [Saxon::XSLT::Executable] the executable stylesheet
      def compile(source, &block)
        Saxon::XSLT::Executable.new(
          new_compiler.compile(source.to_java),
          evaluation_context.define(block)
        )
      end

      def create(&block)
        new_evaluation_context = evaluation_context.define(block)
        self.class.new(@s9_processor, new_evaluation_context)
      end

      private

      def new_compiler
        compiler = @s9_processor.newXsltCompiler
        compiler.declareDefaultCollation(default_collation) unless default_collation.nil?
        static_parameters.each do |qname, value|
          compiler.setParameter(qname.to_java, value.to_java)
        end
        compiler
      end
    end
  end
end
