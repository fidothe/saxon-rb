require_relative '../qname'
module Saxon
  module XSLT
    # Represents the static context for an XSLT compiler. {StaticContext}s are immutable.
    class StaticContext
      # methods used by both {StaticContext} and {StaticContext::DSL}
      module Common
        # @param args [Hash]
        # @option args [Hash<String => java.text.Collator>] :declared_collations Hash of URI => Collator bindings
        # @option args [String] :default_collation URI of the default collation
        def initialize(args = {})
          @declared_collations = args.fetch(:declared_collations, {}).freeze
          @default_collation = args.fetch(:default_collation, nil).freeze
        end

        # returns the context details in a hash suitable for initializing a new one
        # @return [Hash<Symbol => Hash,null>] the args hash
        def args_hash
          {
            declared_collations: @declared_collations,
            default_collation: @default_collation
          }
        end
      end

      # Provides the hooks for constructing a {StaticContext} with a DSL.
      # @api private
      class DSL
        include Common

        # Create an instance based on the args hash, and execute the passed in Proc/lambda against it using {#instance_exec} and return a
        # new {StaticContext} with the results
        # @param block [Proc] a Proc/lambda (or <tt>to_proc</tt>'d containing DSL calls
        # @return [Saxon::XPath::StaticContext]
        def self.define(block, args = {})
          dsl = new(args)
          dsl.instance_exec(&block) unless block.nil?
          StaticContext.new(dsl.args_hash)
        end

        # Add one or more collations to the context. Calling this multiple
        # times will add to the set of collations, not replace it. If duplicate
        # URI keys are used in later {#collation} calls, the last one will win
        # and be the collation for that key
        #
        # @param collations [Hash<String => java.text.Collator>] Hash of URI, <tt>Collator</tt> key-value pairs.
        def collation(collations = {})
          @declared_collations = @declared_collations.merge(collations).freeze
        end

        # Set the default Collation to use
        #
        # @param collation_uri [String] The URI of the Collation to set as the default
        def default_collation(collation_uri)
          @default_collation = collation_uri
        end

        private
      end

      include Common

      # Executes the Proc/lambda passed in with a new instance of
      # {StaticContext} as <tt>self</tt>, allowing the DSL methods to be
      # called in a DSL-ish way
      #
      # @param block [Proc] the block of DSL calls to be executed
      # @return [Saxon::XSLT::StaticContext] the static context created by the block
      def self.define(block)
        DSL.define(block)
      end

      attr_reader :declared_collations, :default_collation

      def define(block)
        DSL.define(block, args_hash)
      end
    end
  end
end
