require_relative '../qname'
require_relative './variable_declaration'

module Saxon
  module XPath
    # Raised when an attempt to declare a variable is made using a string for
    # the qname with a namespace prefix that has not been declared in the
    # context yet
    class MissingVariableNamespaceError < StandardError
      def initialize(variable_name, prefix)
        @variable_name, @prefix = variable_name, prefix
      end

      # error message reports which unbound prefix is a problem, and how it was used
      def to_s
        "Namespace prefix ‘#{@prefix}’ for variable name ‘#{@variable_name}’ is not bound to a URI"
      end
    end

    # @api private
    # Represents the static context for a compiled XPath. {StaticContext}s are immutable.
    class StaticContext
      # methods used by both {StaticContext} and {StaticContext::DSL}
      module Common
        # @param args [Hash]
        # @option args [Hash<Saxon::QName => Saxon::XPath::VariableDeclaration>] :declared_variables Hash of declared variables
        # @option args [Hash<String => String>] :declared_namespaces Hash of namespace bindings prefix => URI
        # @option args [Hash<String => java.text.Collator>] :declared_collations Hash of URI => Collator bindings
        # @option args [String] :default_collation URI of the default collation
        def initialize(args = {})
          @declared_variables = args.fetch(:declared_variables, {}).freeze
          @declared_namespaces = args.fetch(:declared_namespaces, {}).freeze
          @default_collation = args.fetch(:default_collation, nil).freeze
        end

        # returns the context details in a hash suitable for initializing a new one
        # @return [Hash<Symbol => Hash,null>] the args hash
        def args_hash
          {
            declared_namespaces: @declared_namespaces,
            declared_variables: @declared_variables,
            default_collation: @default_collation
          }
        end
      end

      # @api public
      # Provides the hooks for constructing a {StaticContext} with a DSL.
      class DSL
        include Common

        # @api private
        # Create an instance based on the args hash, and execute the passed in Proc/lambda against it using <tt>#instance_exec</tt> and return a
        # new {StaticContext} with the results
        # @param block [Proc] a Proc/lambda (or <tt>to_proc</tt>'d containing DSL calls
        # @return [Saxon::XPath::StaticContext]
        def self.define(block, args = {})
          dsl = new(args)
          dsl.instance_exec(&block) unless block.nil?
          StaticContext.new(dsl.args_hash)
        end

        # Set the default Collation to use. This should be one of the special
        # collation URIs Saxon recognises, or one that has been registered
        # using Saxon::Processor#declare_collations on the Processor that
        # created the {XPath::Compiler} this context is for.
        #
        # @param collation_uri [String] The URI of the Collation to set as the default
        def default_collation(collation_uri)
          @default_collation = collation_uri
        end

        # Bind prefixes to namespace URIs
        #
        # @param namespaces [Hash{String, Symbol => String}]
        def namespace(namespaces = {})
          @declared_namespaces = @declared_namespaces.merge(namespaces.map { |k, v| [k.to_s, v] }.to_h).freeze
        end

        # Declare a XPath variable's existence in the context
        #
        # @param qname [String, Saxon::QName] The name of the variable as
        #   explicit QName or prefix:name string form. The string form requires
        #   the namespace prefix to have already been declared with {#namespace}
        # @param sequence_type [String, Saxon::SequenceType, null] The type of
        #   the variable, either as a string using the same form as an XSLT
        #   <tt>as=""</tt> type definition, or as a {Saxon::SequenceType} directly.
        #
        #   If it's nil, then the default <tt>item()*</tt> – anything – type declaration is used
        def variable(qname, sequence_type = nil)
          qname = resolve_variable_qname(qname)
          @declared_variables = @declared_variables.merge({
            qname => resolve_variable_declaration(qname, sequence_type)
          }).freeze
        end

        private

        def resolve_variable_qname(qname_or_string)
          Saxon::QName.resolve(qname_or_string, @declared_namespaces)
        end

        def resolve_variable_declaration(qname, sequence_type = nil)
          Saxon::XPath::VariableDeclaration.new(qname, Saxon.SequenceType(sequence_type || 'item()*'))
        end
      end

      include Common

      # Executes the Proc/lambda passed in with a new instance of
      # {StaticContext} as <tt>self</tt>, allowing the DSL methods to be
      # called in a DSL-ish way
      #
      # @param block [Proc] the block of DSL calls to be executed
      # @return [Saxon::XPath::StaticContext] the static context created by the block
      def self.define(block)
        DSL.define(block)
      end

      # @return [String] The default collation URI as a String
      attr_reader :default_collation
      # @return [Hash<Saxon::QName => Saxon::XPath::VariableDeclaration] the declared variables
      attr_reader :declared_variables
      # @return [Hash<String => String>] the declared namespaces, as a prefix => uri hash
      attr_reader :declared_namespaces

      # @return [Saxon::QName]
      # @overload resolve_variable_qname(qname)
      #   returns the QName
      #   @param qname_or_string [Saxon::QName] the name as a QName
      # @overload resolve_variable_qname(string)
      #   resolve the <tt>prefix:local_name</tt> string into a proper QName by
      #   looking up the prefix in the {#declared_namespaces}
      #   @param qname_or_string [String] the name as a string
      def resolve_variable_qname(qname_or_string)
        Saxon::QName.resolve(qname_or_string, declared_namespaces)
      end

      # @api private
      # Create a new {StaticContext} based on this one. Passed Proc is evaluated in the same way as {DSL.define}
      def define(block)
        DSL.define(block, args_hash)
      end
    end
  end
end
