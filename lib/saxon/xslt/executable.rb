require_relative 'static_context'
require_relative '../serializer'
require_relative '../xdm_value'
require_relative '../qname'

module Saxon
  module XSLT
    # Represents a compiled XPaGth query ready to be executed
    class Executable
      # @return [XSLT::StaticContext] the XPath's static context
      attr_reader :static_context

      # @api private
      # @param s9_xslt_executable [net.sf.saxon.s9api.XsltExecutable] the
      #   Saxon compiled XPath object
      # @param static_context [XPath::StaticContext] the XPath's static
      #   context
      def initialize(s9_xslt_executable, static_context)
        @s9_xslt_executable, @static_context = s9_xslt_executable, static_context
      end

      def apply_templates(source, opts = {})
        transformation(opts).apply_templates(source)
      end

      def call_template(template_name, opts = {})
        transformation(opts).call_template(template_name)
      end

      # @return [net.sf.saxon.s9api.XsltExecutable] the underlying Saxon
      #   <tt>XsltExecutable</tt>
      def to_java
        @s9_xslt_executable
      end

      private

      def transformation(opts)
        Transformation.new(opts.merge({
          s9_transformer: @s9_xslt_executable.load30,
        }))
      end
    end

    class Result
      attr_reader :xdm_value

      def initialize(xdm_value, s9_transformer)
        @xdm_value, @s9_transformer = xdm_value, s9_transformer
      end

      def to_s
        serializer = Serializer.new(@s9_transformer.newSerializer)
        serializer.serialize(xdm_value.to_java)
      end
    end

    class Transformation
      attr_reader :s9_transformer, :opts

      def initialize(args)
        @s9_transformer = args.fetch(:s9_transformer)
        @destination = args.fetch(:destination, nil)
        @opts = args.reject { |opt, _|
          [:s9_transformer, :destination].include?(opt)
        }
        @raw = false
      end

      def apply_templates(source)
        transformation_result(:applyTemplates, source)
      end

      def call_template(template_name)
        transformation_result(:callTemplate, resolve_qname(template_name))
      end

      private

      def transformation_result(invocation_method, invocation_arg)
        set_opts!
        transformer_args = [invocation_method, invocation_arg.to_java, destination].compact
        Result.new(result_xdm_value(s9_transformer.send(*transformer_args)), s9_transformer)
      end

      def result_xdm_value(transformer_return_value)
        XdmValue.wrap_s9_xdm_value(
          transformer_return_value.nil? ? destination.getXdmNode : transformer_return_value
        )
      end

      def destination
        @destination ||= begin
          Saxon::S9API::XdmDestination.new unless raw?
        end
      end

      def set_opts!
        opts.each do |opt, value|
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
        s9_transformer.setInitialMode(resolve_qname(mode_name).to_java)
      end

      def resolve_qname(qname)
        case qname
        when Saxon::QName
          qname
        else
          raise Saxon::QName::PrefixedStringWithoutNSURIError if qname.to_s.include?(':')
          Saxon::QName.create(local_name: qname.to_s)
        end
      end
    end
  end
end
