module Saxon
  module XPath
    class StaticContext
      class DSL
        def self.define(block)
          new.define(block)
        end

        def initialize
          @declared_collations = {}
          @declared_variables = {}
          @declared_namespaces = {}
          @default_collation_uri = nil
        end

        # @api private
        def define(block)
          instance_exec(&block) unless block.nil?
          StaticContext.new(args_hash)
        end

        # Add one or more collations to the context. Calling this multiple
        # times will add to the set of collations, not replace it. If duplicate
        # URI keys are used in later {#collation} calls, the last one will win
        # and be the collation for that key
        #
        # @param collations [Hash<String => java.text.Collator>] Hash of URI, <tt>Collator</tt> key-value pairs.
        def collation(collations = {})
          @declared_collations = @declared_collations.merge(collations)
        end

        # Set the default Collation to use 
        #
        # @param collation_uri [String] The URI of the Collation to set as the default
        def default_collation(collation_uri)
          @default_collation = collation_uri
        end

        private

        def args_hash
          {
            declared_namespaces: @declared_namespaces, declared_variables: @declared_variables,
            declared_collations: @declared_collations, default_collation: @default_collation
          }
        end
      end

      attr_reader :declared_variables, :declared_namespaces, :declared_collations, :default_collation

      def initialize(args = {})
        @declared_variables = args.fetch(:declared_variables, [])
        @declared_namespaces = args.fetch(:declared_namespaces, {})
        @declared_collations = args.fetch(:declared_collations, [])
        @default_collation = args.fetch(:default_collation, nil)
      end
    end
  end
end
