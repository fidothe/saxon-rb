require 'forwardable'
require_relative './evaluation_context'
require_relative './executable'

module Saxon
  module XSLT
    # The simplest way to construct an {XSLT::Compiler} is to call
    # {Saxon::Processor#xslt_compiler}.
    #
    #     processor = Saxon::Processor.create
    #     # Simplest, default options
    #     compiler = processor.xslt_compiler
    #
    # In order to set compile-time options, declare static compile-time
    # parameters then pass a block to the method using the DSL syntax (see
    # {Saxon::XSLT::EvaluationContext::DSL}
    #
    #     compiler = processor.xslt_compiler {
    #       static_parameters 'param' => 'value'
    #       default_collation 'https://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive/'
    #     }
    #
    # The static evaluation context for a Compiler cannot be changed, you must
    # create a new one with the context you want. It’s very simple to create a
    # new Compiler based on an existing one. Declaring a parameter with a an
    # existing name overwrites the old value.
    #
    #     new_compiler = compiler.create {
    #       static_parameters 'param' => 'new value'
    #     }
    #     new_compiler.default_collation #=> "https://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive/"
    #
    # If you wanted to remove a value, you need to start from scratch. You can,
    # of course, extract any data you want from a compiler instance separately
    # and use that to create a new one.
    #
    #     params = compiler.static_parameters
    #     new_compiler = processor.xslt_compiler {
    #       static_parameters params
    #     }
    #     new_compiler.default_collation #=> nil
    #
    # Once you have a compiler, call {Compiler#compile} and pass in a
    # {Saxon::Source} or an existing {Saxon::XDM::Node}. Parameters and other
    # run-time configuration options can be set using a block in the same way as
    # creating a compiler. You'll be returned a {Saxon::XSLT::Executable}.
    #
    #     source = Saxon::Source.create('my.xsl')
    #     xslt = compiler.compile(source) {
    #       initial_template_parameters 'param' => 'other value'
    #     }
    #
    # You can also pass in (or override) parameters at stylesheet execution
    # time, but if you'll be executing the same stylesheet against many
    # documents with the same initial parameters then setting them at compile
    # time is simpler.
    #
    # Global and initial template parameters can be set at compiler creation
    # time, compile time, or execution time. Static parameters can only be set
    # at compiler creation or compile time.
    #
    #     xslt = compiler.compile(source) {
    #       static_parameters 'static-param' => 'static value'
    #       global_parameters 'param' => 'global value'
    #       initial_template_parameters 'param' => 'other value'
    #       initial_template_tunnel_parameters 'param' => 'tunnel value'
    #     }
    #
    # To set an Error reporter, which will be called for warnings and runtime
    # xslt/xpath errors you can pass in a block which will be called with a
    # Saxon::XMLProcessingError. Processing will continue after a warning, but
    # for other kinds of error will be aborted, after your reporter code has
    # run, with a raised Exception.
    #
    #     xslt = compiler.compile(source) {
    #       error_reporter do |error|
    #         ...
    #       end
    #     }
    #
    # You can also pass a lambda or an object which responds to +#call()+:
    #
    #     xslt = compiler.compile(source) {
    #       error_reporter ->(error) { ... }
    #     }
    #
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
        new_evaluation_context = evaluation_context.define(block)
        s9_compiler = new_compiler(new_evaluation_context)
        Saxon::XSLT::Executable.new(
          s9_compiler.compile(source.to_java),
          new_evaluation_context
        )
      end

      # Allows the creation of a new {Compiler} starting from a copy of this
      # Compiler's static context. As with {.create}, passing a block gives
      # access to a DSL for setting up the compiler's static context.
      #
      # @yield An XSLT compiler DSL block
      # @return [Saxon::XSLT::Compiler] the new compiler instance
      def create(&block)
        new_evaluation_context = evaluation_context.define(block)
        self.class.new(@s9_processor, new_evaluation_context)
      end

      private

      def new_compiler(evaluation_context)
        compiler = @s9_processor.newXsltCompiler
        compiler.declareDefaultCollation(evaluation_context.default_collation) unless evaluation_context.default_collation.nil?
        evaluation_context.static_parameters.each do |qname, value|
          compiler.setParameter(qname.to_java, value.to_java)
        end
        compiler
      end
    end
  end
end
