require 'forwardable'
require_relative 'evaluation_context'
require_relative 'invocation'
require_relative '../serializer'
require_relative '../xdm'
require_relative '../qname'
require_relative '../feature_flags'

module Saxon
  module XSLT
    # Represents a compiled XSLT stylesheet ready to be executed
    #
    # Once you have a compiled stylesheet, then it can be executed against a
    # source document in a variety of ways.
    #
    # First, you can use the traditional *apply templates* ,method, which was
    # the only way in XSLT 1.
    #
    #     input = Saxon::Source.create('input.xml')
    #     result = xslt.apply_templates(input)
    #
    # Next, you can call a specific named template (new in XSLT 2).
    #
    #     result = xslt.call_template('template-name')
    #
    # Note that there's no input document here. If your XSLT needs a global
    # context item set when you invoke it via a named template, then you can do
    # that, too:
    #
    #     input = processor.XML('input.xml')
    #     result = xslt.call_template('template-name', {
    #       global_context_item: input
    #     })
    #
    # Global and initial template parameters can be set at compiler creation
    # time, compile time, or execution time.
    #
    # Initial template parameters relate to parameters passed to the *first*
    # template run (either the first template matched when called with
    # {Executable#apply_templates}, or the named template called with
    # {Executable#call_template}).
    #
    # <b>Initial template parameters</b> are essentially implied +<xsl:with-parameter
    # tunnel="no">+ elements. <b>Initial template tunnel parameters</b> are implied
    # +<xsl:with-parameter tunnel="yes">+ elements.
    #
    #     xslt.apply_templates(input, {
    #       global_parameters: {'param' => 'global value'},
    #       initial_template_parameters: {'param' => 'other value'},
    #       initial_template_tunnel_parameters: {'param' => 'tunnel value'}
    #     })
    #
    # Remember that if you need to use a parameter name which uses a namespace
    # prefix, you must use an explicit {Saxon::QName} to refer to it.
    class Executable
      extend Forwardable
      extend Saxon::FeatureFlags::Helpers

      attr_reader :evaluation_context
      private :evaluation_context

      # @api private
      # @param s9_xslt_executable [net.sf.saxon.s9api.XsltExecutable] the
      #   Saxon compiled XSLT object
      # @param evaluation_context [XSLT::EvaluationContext] the XSLT's evaluation
      #   context
      def initialize(s9_xslt_executable, evaluation_context)
        @s9_xslt_executable, @evaluation_context = s9_xslt_executable, evaluation_context
      end

      def_delegators :evaluation_context, :global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters

      # Run the XSLT by applying templates against the provided {Saxon::Source}
      # or {Saxon::XDM::Node}.
      #
      # @note Any {QName}s supplied as strings MUST be resolvable as a QName
      # without extra information, so they must be prefix-less (so, 'name', and
      # never 'ns:name')
      #
      # @param source [Saxon::Source, Saxon::XDM::Node] the Source or Node that
      #   will be used as the global context item
      # @param opts [Hash] a hash of options for invoking the transformation
      # @option opts [Boolean] :raw (false) Whether the transformation should be
      #   executed 'raw', because it is expected to return a simple XDM Value
      #   (like a number, or plain text) and not an XML document.
      # @option opts [String, Saxon::QName] :mode The initial mode to use when
      #   processing starts.
      # @option opts [Hash<String, Saxon::QName => Object>] :global_parameters
      #   Additional global parameters to set. Setting already-defined
      #   parameters will replace their value for this invocation of the XSLT
      #   only, it won't affect the {XSLT::Compiler}'s context.
      # @option opts [Hash<String, Saxon::QName => Object>]
      #   :initial_template_parameters Additional parameters to pass to the
      #   first template matched. Setting already-defined parameters will
      #   replace their value for this invocation of the XSLT only, it won't
      #   affect the {XSLT::Compiler}'s context.
      # @option opts [Hash<String, Saxon::QName => Object>]
      #   :initial_template_tunnel_parameters Additional tunnelling parameters
      #   to pass to the first template matched. Setting already-defined
      #   parameters will replace their value for this invocation of the XSLT
      #   only, it won't affect the {XSLT::Compiler}'s context.
      # @return [Saxon::XSLT::Invocation] the transformation result
      def apply_templates(source, opts = {})
        transformation(opts).apply_templates(source)
      end

      # Run the XSLT by calling the named template.
      #
      # @note Any {QName}s supplied as Strings (e.g. for the template name)
      # MUST be resolvable as a QName without extra information, so they must be
      # prefix-less (so, 'name', and never 'ns:name')
      #
      # @param template_name [String, Saxon::QName, nil] the name of the
      #   template to be invoked. Passing +nil+ will invoke the default named
      #   template (+xsl:default-template+)
      # @param opts [Hash] a hash of options for invoking the transformation
      # @option opts [Boolean] :raw (false) Whether the transformation should be
      #   executed 'raw', because it is expected to return a simple XDM Value
      #   (like a number, or plain text) and not an XML document.
      # @option opts [String, Saxon::QName] :mode The name of the initial mode
      #   to use when processing starts.
      # @option opts [Hash<String, Saxon::QName => Object>] :global_parameters
      #   Additional global parameters to set. Setting already-defined
      #   parameters will replace their value for this invocation of the XSLT
      #   only, it won't affect the {XSLT::Compiler}'s context.
      # @option opts [Hash<String, Saxon::QName => Object>]
      #   :initial_template_parameters Additional parameters to pass to the
      #   first template matched. Setting already-defined parameters will
      #   replace their value for this invocation of the XSLT only, it won't
      #   affect the {XSLT::Compiler}'s context.
      # @option opts [Hash<String, Saxon::QName => Object>]
      #   :initial_template_tunnel_parameters Additional tunnelling parameters
      #   to pass to the first template matched. Setting already-defined
      #   parameters will replace their value for this invocation of the XSLT
      #   only, it won't affect the {XSLT::Compiler}'s context.
      # @return [Saxon::XSLT::Invocation] the transformation result
      def call_template(template_name = nil, opts = {})
        transformation(opts).call_template(template_name)
      end

      # Invoke a named function in the XSLT.
      #
      # @note Function name {QName}s have to have prefixes, so they can't be
      #   supplied as {::String}s. Any other {QName}s supplied as {::String}s (e.g.
      #   for the template name) MUST be resolvable as a QName without extra
      #   information, so they must be prefix-less (so, 'name', and never
      #   'ns:name')
      # @note the function you're calling needs to be have been defined with
      #   +visibility="public"+ or +visibility="final"+
      #
      # @param function_name [Saxon::QName] the name of the function to be
      #   invoked.
      # @param opts [Hash] a hash of options for invoking the transformation
      # @option opts [Boolean] :raw (false) Whether the transformation should be
      #   executed 'raw', because it is expected to return a simple XDM Value
      #   (like a number, or plain text) and not an XML document.
      # @option opts [Hash<String, Saxon::QName => Object>] :global_parameters
      #   Additional global parameters to set. Setting already-defined
      #   parameters will replace their value for this invocation of the XSLT
      #   only, it won't affect the {XSLT::Compiler}'s context.
      # @return [Saxon::XSLT::Invocation] the transformation result
      def call_function(function_name, opts = {})
        args = opts.fetch(:args, [])
        transformation(opts.reject { |k, v| k == :args }).call_function(function_name, args)
      end

      # Create a {Serializer::Object} configured using the options that were set
      # by +<xsl:output>+.
      #
      # @return [Saxon::Serializer::Object] the Serializer
      def serializer
        Saxon::Serializer::Object.new(@s9_xslt_executable.load30.newSerializer)
      end
      requires_saxon_version :serializer, '>= 9.9'

      # @return [net.sf.saxon.s9api.XsltExecutable] the underlying Saxon
      #   +XsltExecutable+
      def to_java
        @s9_xslt_executable
      end

      private

      def transformation(opts)
        Transformation.new(params_merged_opts(opts).merge({
          s9_transformer: @s9_xslt_executable.load30,
        }))
      end

      def params_merged_opts(opts)
        merged_opts = params_hash.dup
        opts.each do |key, value|
          if [:global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters].include?(key)
            merged_opts[key] = merged_opts.fetch(key, {}).merge(XSLT::ParameterHelper.process_parameters(value))
          else
            merged_opts[key] = value
          end
        end
        merged_opts
      end

      def params_hash
        @params_hash ||= begin
          params_hash = {}
          params_hash[:global_parameters] = global_parameters unless global_parameters.empty?
          params_hash[:initial_template_parameters] = initial_template_parameters unless initial_template_parameters.empty?
          params_hash[:initial_template_tunnel_parameters] = initial_template_tunnel_parameters unless initial_template_tunnel_parameters.empty?
          params_hash
        end.freeze
      end
    end

    # @api private
    # Represents a loaded XSLT transformation ready to be applied against a
    # context node.
    class Transformation
      # A list of valid option names for the transform
      VALID_OPTS = [:raw, :mode, :global_context_item, :global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters]

      attr_reader :s9_transformer, :opts
      private :s9_transformer, :opts

      # Return the default initial template namne for XSLT 3 named-template invocation
      # @return [Saxon::QName] the default initial template QName
      def self.default_initial_template
        @default_initial_template ||= Saxon::QName.clark('{http://www.w3.org/1999/XSL/Transform}initial-template')
      end

      # @api private
      def initialize(args)
        @s9_transformer = args.fetch(:s9_transformer)
        @destination = args.fetch(:destination, nil)
        @opts = args.reject { |opt, _|
          [:s9_transformer, :destination].include?(opt)
        }
        @raw = false
      end

      # Apply templates to Source, using all the context set up when we were
      # created.
      def apply_templates(source)
        transformation_invocation(:applyTemplates, source.to_java)
      end

      # Call the named template, using all the context set up when we were
      # created.
      def call_template(template_name)
        transformation_invocation(:callTemplate, resolve_template_name(template_name))
      end

      # Call the named function, using all the context set up when we were
      # created.
      def call_function(function_name, args)
        function_name = Saxon::QName.resolve(function_name).to_java
        transformation_invocation(:callFunction, function_name, function_args(args))
      end

      private

      def transformation_invocation(invocation_method, *invocation_args)
        set_opts!
        XSLT::Invocation.new(s9_transformer, invocation_lambda(invocation_method, invocation_args), raw?)
      end

      def invocation_lambda(invocation_method, invocation_args)
        ->(destination) {
          if destination.nil?
            s9_transformer.send(invocation_method, *invocation_args)
          else
            s9_transformer.send(invocation_method, *invocation_args, destination.to_java)
          end
        }
      end

      def resolve_template_name(template_name)
        return self.class.default_initial_template.to_java if template_name.nil?
        Saxon::QName.resolve(template_name).to_java
      end

      def function_args(args = [])
        args.map { |val| Saxon::XDM.Value(val).to_java }.to_java(S9API::XdmValue)
      end

      def set_opts!
        opts.each do |opt, value|
          raise BadOptionError, opt unless VALID_OPTS.include?(opt)
          send(opt, value)
        end
      end

      def raw(value)
        @raw = value
      end

      def raw?
        @raw
      end

      def mode(mode_name)
        s9_transformer.setInitialMode(Saxon::QName.resolve(mode_name).to_java)
      end

      def global_context_item(xdm_item)
        s9_transformer.setGlobalContextItem(xdm_item.to_java)
      end

      def global_parameters(parameters)
        s9_transformer.setStylesheetParameters(XSLT::ParameterHelper.to_java(parameters))
      end

      def initial_template_parameters(parameters)
        s9_transformer.setInitialTemplateParameters(XSLT::ParameterHelper.to_java(parameters), false)
      end

      def initial_template_tunnel_parameters(parameters)
        s9_transformer.setInitialTemplateParameters(XSLT::ParameterHelper.to_java(parameters), true)
      end
    end

    # Raised if a bad option name is passed in the options hash to
    # Executable#apply_templates et al
    class BadOptionError < StandardError
      def initialize(option_name)
        @option_name = option_name
      end

      # return error message including the option name
      def to_s
        "Option :#{@option_name} is not a recognised option."
      end
    end
  end
end
