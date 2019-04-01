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

      def to_s
        "Namespace prefix ‘#{@prefix}’ for variable name ‘#{@variable_name}’ is not bound to a URI"
      end
    end

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

      # methods for resolving a QName represented as a <tt>prefix:local-name</tt> string into a {Saxon::QName} by looking the prefix up in declared namespaces
      module Resolver
        # Resolve a QName string into a {Saxon::QName}.
        #
        # If the arg is a {Saxon::QName} already, it just gets returned. If
        # it's an instance of the underlying Saxon Java QName, it'll be wrapped
        # into a {Saxon::QName}
        #
        # If the arg is a string, it's resolved by using {resolve_variable_name}
        #
        # @param qname_or_string [String, Saxon::QName] the qname to resolve
        # @return [Saxon::QName]
        def self.resolve_variable_qname(qname_or_string, namespaces)
          case qname_or_string
          when String
            resolve_variable_name(qname_or_string, namespaces)
          when Saxon::QName
            qname_or_string
          when Saxon::S9API::QName
            Saxon::QName.new(qname_or_string)
          end
        end

        # Resolve a QName string of the form <tt>"prefix:local-name"</tt> into a
        # {Saxon::QName} by looking up the namespace URI in a hash of
        # <tt>"prefix" => "namespace-uri"</tt>
        #
        # @param qname_string [String] the QName as a <tt>"prefix:local-name"</tt> string
        # @param namespaces [Hash<String => String>] the set of namespaces as a hash of <tt>"prefix" => "namespace-uri"</tt>
        # @return [Saxon::QName]
        def self.resolve_variable_name(qname_string, namespaces)
          local_name, prefix = qname_string.split(':').reverse
          uri = nil

          if prefix
            uri = namespaces[prefix]
            raise MissingVariableNamespaceError.new(qname_string, prefix) if uri.nil?
          end

          Saxon::QName.create(prefix: prefix, uri: uri, local_name: local_name)
        end
      end

      # Provides the hooks for constructing a {StaticContext} with a DSL.
      # @api private
      class DSL
        include Common

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
          @declared_namespaces = @declared_namespaces.merge(namespaces.transform_keys(&:to_s)).freeze
        end

        # Declare a XPath variable's existence in the context
        #
        # @param qname [String, Saxon::QName] The name of the variable as
        # explicit QName or prefix:name string form. The string form requires
        # the namespace prefix to have already been declared with {#namespace}
        # @param type [String, Hash{Symbol => String, Class}, null] The type of the
        # variable, either as a string using the same form as an XSLT
        # <tt>as=""</tt> type definition, or as a hash of one key/value where
        # that key is a Symbol taken from {Saxon::OccurenceIndicator} and the
        # value is either a Class that {Saxon::ItemType} can convert to its
        # XDM equivalent (e.g. {::String}), or a string that {Saxon::ItemType}
        # can parse into an XDM type (e.g. <tt>xs:string</tthat
        # {Saxon::ItemType} can parse into an XDM type (e.g.
        # <tt>xs:string</tt> or <tt>element()</tt>).
        # If it's nil, then the default <tt>item()*</tt> – anything – type declaration is used
        def variable(qname, type = nil)
          qname = resolve_variable_qname(qname)
          @declared_variables = @declared_variables.merge({
            qname => resolve_variable_declaration(qname, type)
          }).freeze
        end

        private

        def resolve_variable_qname(qname_or_string)
          Resolver.resolve_variable_qname(qname_or_string, @declared_namespaces)
        end

        def resolve_variable_type_decl(type_decl)
          case type_decl
          when String
            occurence_char = type_decl[-1]
            occurence = case occurence_char
            when '?'
              {zero_or_one: type_decl[0..-2]}
            when '+'
              {one_or_more: type_decl[0..-2]}
            when '*'
              {zero_or_more: type_decl[0..-2]}
            else
              {one: type_decl}
            end
          when Hash
            type_decl
          end
        end

        def resolve_variable_declaration(qname, type)
          args_hash = resolve_variable_type_decl(type) || {}
          args_hash[:qname] = qname
          Saxon::XPath::VariableDeclaration.new(args_hash)
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

      attr_reader :declared_variables, :declared_namespaces, :default_collation

      # @return [Saxon::QName]
      # @overload resolve_variable_qname(qname)
      #   returns the QName
      #   @param qname_or_string [Saxon::QName] the name as a QName
      # @overload resolve_variable_qname(string)
      #   resolve the <tt>prefix:local_name</tt> string into a proper QName by
      #   looking up the prefix in the {#declared_namespaces}
      #   @param qname_or_string [String] the name as a string
      def resolve_variable_qname(qname_or_string)
        Resolver.resolve_variable_qname(qname_or_string, declared_namespaces)
      end

      def define(block)
        DSL.define(block, args_hash)
      end
    end
  end
end
