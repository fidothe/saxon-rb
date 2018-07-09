require 'saxon/s9api'
require 'saxon/source'
require 'saxon/configuration'

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
