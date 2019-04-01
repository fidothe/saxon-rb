require 'saxon/s9api'
require 'saxon/source'
require 'saxon/configuration'
require 'saxon/document_builder'
require 'saxon/xpath'
require 'saxon/xslt'

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
    # @yield An XPath compiler DSL block, see {Saxon::XSLT::Compiler.create}
    # @return [Saxon::XSLT::Compiler] a new XSLT compiler
    def xslt_compiler(&block)
      Saxon::XSLT::Compiler.create(self, &block)
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
  end
end
