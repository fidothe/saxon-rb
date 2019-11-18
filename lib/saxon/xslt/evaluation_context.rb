require 'set'
require_relative '../qname'

module Saxon
  module XSLT
    # Represents the evaluation context for an XSLT compiler, and stylesheets
    # compiled using one. {EvaluationContext}s are immutable.
    class EvaluationContext
      # methods used by both {EvaluationContext} and {EvaluationContext::DSL}
      module Common
        # @param args [Hash]
        # @option args [String] default_collation URI of the default collation
        # @option args [Hash<String,Symbol,Saxon::QName =>
        #   Object,Saxon::XDM::Value] static_parameters Hash of QName => value
        #   bindings for static (compile-time) parameters for this compiler
        def initialize(args = {})
          @default_collation = args.fetch(:default_collation, nil).freeze
          @static_parameters = args.fetch(:static_parameters, {}).freeze
          @global_parameters = args.fetch(:global_parameters, {}).freeze
          @initial_template_parameters = args.fetch(:initial_template_parameters, {}).freeze
          @initial_template_tunnel_parameters = args.fetch(:initial_template_tunnel_parameters, {}).freeze
        end

        # returns the context details in a hash suitable for initializing a new one
        # @return [Hash<Symbol => Hash,null>] the args hash
        def args_hash
          check_for_clashing_parameters!
          {
            default_collation: @default_collation,
            static_parameters: @static_parameters,
            global_parameters: @global_parameters,
            initial_template_parameters: @initial_template_parameters,
            initial_template_tunnel_parameters: @initial_template_tunnel_parameters
          }
        end

        private

        def check_for_clashing_parameters!
          @checked ||= begin
            if Set.new(@static_parameters.keys).intersect?(Set.new(@global_parameters.keys))
              raise GlobalAndStaticParameterClashError
            else
              true
            end
          end
        end
      end

      # Provides the hooks for constructing a {EvaluationContext} with a DSL.
      class DSL
        include Common

        # @api private
        # Create an instance based on the args hash, and execute the passed in Proc/lambda against it using <tt>#instance_exec</tt> and return a
        # new {EvaluationContext} with the results
        # @param block [Proc] a Proc/lambda (or <tt>to_proc</tt>'d containing DSL calls
        # @return [Saxon::XSLT::EvaluationContext]
        def self.define(block, args = {})
          dsl = new(args)
          dsl.instance_exec(&block) unless block.nil?
          EvaluationContext.new(dsl.args_hash)
        end

        # Set the default Collation to use. This should be one of the special
        # collation URIs Saxon recognises, or one that has been registered
        # using Saxon::Processor#declare_collations on the Processor that
        # created the {XSLT::Compiler} this context is for.
        #
        # @param collation_uri [String] The URI of the Collation to set as the default
        def default_collation(collation_uri)
          @default_collation = collation_uri
        end

        # Set the value for static parameters (those that must be known at
        # compile-time to avoid an error), as a hash of QName => Value pairs.
        # Parameter QNames can be declared as Strings or Symbols if they are
        # not in any namespace, otherwise an explicit {Saxon::QName} must be
        # used. Values can be provided as explicit XDM::Values:
        # {Saxon::XDM::Value}, {Saxon::XDM::Node}, and {Saxon::XDM::AtomicValue}, or
        # as Ruby objects which will be converted to {Saxon::XDM::AtomicValue}s
        # in the usual way.
        #
        # @param parameters [Hash<String,Symbol,Saxon::QName =>
        #   Object,Saxon::XDM::Value>] Hash of QName => value
        def static_parameters(parameters = {})
          @static_parameters = @static_parameters.merge(process_parameters(parameters)).freeze
        end

        # Set the values for global parameters (those that are available to all templates and functions).
        #
        # @see EvaluationContext#static_parameters for details of the argument format
        #
        # @param parameters [Hash<String,Symbol,Saxon::QName =>
        #   Object,Saxon::XDM::Value>] Hash of QName => value
        def global_parameters(parameters = {})
          @global_parameters = @global_parameters.merge(process_parameters(parameters)).freeze
        end

        # Set the values for parameters made available only to the initial
        # template invoked (either via apply_templates or call_template),
        # effectively as if <tt><xsl:with-param tunnel="no"></tt> was being used.
        #
        # @see EvaluationContext#static_parameters for details of the argument format
        #
        # @param parameters [Hash<String,Symbol,Saxon::QName =>
        #   Object,Saxon::XDM::Value>] Hash of QName => value
        def initial_template_parameters(parameters = {})
          @initial_template_parameters = @initial_template_parameters.merge(process_parameters(parameters))
        end

        # Set the values for tunneling parameters made available only to the initial
        # template invoked (either via apply_templates or call_template),
        # effectively as if <tt><xsl:with-param tunnel="yes"></tt> was being used.
        #
        # @see EvaluationContext#static_parameters for details of the argument format
        #
        # @param parameters [Hash<String,Symbol,Saxon::QName =>
        #   Object,Saxon::XDM::Value>] Hash of QName => value
        def initial_template_tunnel_parameters(parameters = {})
          @initial_template_tunnel_parameters = @initial_template_tunnel_parameters.merge(process_parameters(parameters))
        end

        private

        def process_parameters(parameters)
          XSLT::ParameterHelper.process_parameters(parameters)
        end
      end

      include Common

      # Executes the Proc/lambda passed in with a new instance of
      # {EvaluationContext} as <tt>self</tt>, allowing the DSL methods to be
      # called in a DSL-ish way
      #
      # @param block [Proc] the block of DSL calls to be executed
      # @return [Saxon::XSLT::EvaluationContext] the static context created by the block
      def self.define(block)
        DSL.define(block)
      end

      attr_reader :default_collation, :static_parameters, :global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters

      def define(block)
        block.nil? ? self : DSL.define(block, args_hash)
      end
    end

    # Error raised when a global and static parameter of the same name are
    # declared
    class GlobalAndStaticParameterClashError < StandardError
    end

    module ParameterHelper
      def self.process_parameters(parameters)
        parameters.map { |qname, value|
          [Saxon::QName.resolve(qname), Saxon::XDM.Value(value)]
        }.to_h
      end

      def self.to_java(parameters)
        Hash[parameters.map { |k,v| [k.to_java, v.to_java] }].to_java
      end
    end
  end
end
