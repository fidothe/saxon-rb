require 'saxon/s9api'
require 'saxon/source'
require 'saxon/configuration'
require 'saxon/document_builder'
require 'saxon/xpath'
require 'saxon/xslt'
require 'saxon/serializer'

module Saxon
  # Saxon::Processor wraps the S9API::Processor object. This is the object
  # responsible for creating an XSLT compiler or an XML Document object.
  #
  # The Processor is threadsafe, and can be shared between threads. But, most
  # importantly XSLT or XML objects created by a Processor can only be used
  # with other XSLT or XML objects created by the same Processor instance.
  class Processor
    # Provides a processor with default configuration. Essentially a singleton
    # instance
    # @return [Saxon::Processor]
    def self.default
      @processor ||= create(Saxon::Configuration.default)
    end

    # @param config [File, String, IO, Saxon::Configuration] an open File, or string,
    #   containing a Saxon configuration file; an existing Saxon::Configuration
    #   object
    # @return [Saxon::Processor]
    def self.create(config = nil)
      Saxon::Loader.load!
      case config
      when nil
        licensed_or_config_source = false
      when Saxon::Configuration
        licensed_or_config_source = config.to_java
      else
        licensed_or_config_source = Saxon::Source.create(config).to_java
      end
      s9_processor = S9API::Processor.new(licensed_or_config_source)
      new(s9_processor)
    end

    # @api private
    # @param [net.sf.saxon.s9api.Processor] s9_processor The Saxon Processor
    #   instance to wrap
    def initialize(s9_processor)
      @s9_processor = s9_processor
    end

    # Generate a new DocumentBuilder that uses this Processor.
    # Sharing DocumentBuilders across threads is not recommended/
    #
    # @return [Saxon::DocumentBuilder] A new Saxon::DocumentBuilder
    def document_builder
      Saxon::DocumentBuilder.new(@s9_processor.newDocumentBuilder)
    end

    # Declare custom collations for use by XSLT, XPath, and XQuery processors
    #
    # @param collations [Hash<String => java.text.Collator>] collations to
    #   declare, as a hash of URI => Collator
    def declare_collations(collations)
      collations.each do |uri, collation|
        @s9_processor.declareCollation(uri, collation)
      end
    end
    # Generate a new <tt>XPath::Compiler</tt> that uses this
    # <tt>Processor</tt>. Sharing <tt>XPath::Compiler</tt>s across threads is
    # fine as long as the static context is not changed.
    #
    # @yield An XPath compiler DSL block, see {Saxon::XPath::Compiler.create}
    # @return [Saxon::XPath::Compiler] a new XPath compiler
    def xpath_compiler(&block)
      Saxon::XPath::Compiler.create(self, &block)
    end

    # Generate a new <tt>XSLT::Compiler</tt> that uses this
    # <tt>Processor</tt>. Sharing <tt>XSLT::Compiler</tt>s across threads is
    # fine as long as the static context is not changed.
    #
    # @yield An XSLT compiler DSL block, see {Saxon::XSLT::Compiler.create}
    # @return [Saxon::XSLT::Compiler] a new XSLT compiler
    def xslt_compiler(&block)
      Saxon::XSLT::Compiler.create(self, &block)
    end

    # Generate a new +Serializer+ for directly serializing XDM Values that uses
    # this +Processor+. +Serializer+s are effectively one-shot objects, and
    # shouldn't be reused.
    #
    # @yield the block passed will be called bound to the serializer instance. See
    #   {Saxon::Serializer::Object.create}
    # @return [Saxon::Serializer::Object]
    def serializer(&block)
      Saxon::Serializer::Object.create(self, &block)
    end

    # @return [net.sf.saxon.s9api.Processor] The underlying Saxon processor
    def to_java
      @s9_processor
    end

    # compare equal if the underlying java processor is the same instance for
    # self and other
    # @param other object to compare against
    def ==(other)
      other.to_java === to_java
    end

    # @return [Saxon::Configuration] This processor's configuration instance
    def config
      @config ||= Saxon::Configuration.create(self)
    end

    # Create a {DocumentBuilder} and construct a {Source} and parse some XML.
    # The args are passed to {Saxon::Source.create}, and the returned {Source}
    # is parsed using {DocumentBuilder#build}. If a {Source} is passed in, parse
    # that. Any options in +opts+ will be ignored in that case.
    #
    # @param input [Saxon::Source, IO, File, String, Pathname, URI] the input to
    #   be turned into a {Source} and parsed.
    # @param opts [Hash] for Source creation. See {Saxon::Source.create}.
    # @return [Saxon::XDM::Node] the XML document
    def XML(input, opts = {})
      source = Source.create(input, opts)
      document_builder.build(source)
    end

    # Construct a {Source} containing an XSLT stylesheet, create an
    # {XSLT::Compiler}, and compile the source, returning the {XSLT::Executable}
    # produced. If a {Source} is passed as +input+, then it will be passed
    # through to the compiler and any source-related options in +opts+ will be
    # ignored.
    #
    # @param input [Saxon::Source, IO, File, String, Pathname, URI] the input to
    #   be turned into a {Source} and parsed.
    # @param opts [Hash] for Source creation. See {Saxon::Source.create}.
    # @yield the block is executed as an {XSLT::EvaluationContext::DSL} instance
    #   and applied to the compiler
    # @return [Saxon::XSLT::Executable] the XSLT Executable
    def XSLT(input, opts = {}, &block)
      source = Source.create(input, opts)
      xslt_compiler(&block).compile(source)
    end
  end
end
