require 'saxon/s9api'
require 'saxon/parse_options'
require 'saxon/configuration/feature'

module Saxon
  # Wraps the <tt>net.sf.saxon.Configuration</tt> class.
  #
  # See {net.sf.saxon.Configuration} for details of what configuration options
  # are available and what values they accept.
  #
  # See {net.sf.saxon.lib.FeatureKeys} for details of the constant names used to
  # access the values
  class Configuration
    DEFAULT_SEMAPHORE = Mutex.new
    private_constant :DEFAULT_SEMAPHORE

    # Provides a processor with default configuration. Essentially a singleton
    # instance
    # @return [Saxon::Configuration]
    def self.default
      DEFAULT_SEMAPHORE.synchronize do
        @config ||= create
      end
    end

    # @param processor [Saxon::Processor] a Saxon::Processor instance
    # @return [Saxon::Configuration]
    def self.create(processor = nil)
      Saxon::Loader.load!
      if processor
        config = processor.to_java.underlying_configuration
      else
        config = Saxon::S9API::Configuration.new
      end
      new(config)
    end

    # @param license_path [String] the absolute path to a Saxon PE or EE
    #   license file
    # @return [Saxon::Configuration]
    def self.create_licensed(license_path)
      Saxon::Loader.load!
      java_config = Saxon::S9API::Configuration.makeLicensedConfiguration(nil, nil)
      config = new(java_config)
      config[:LICENSE_FILE_LOCATION] = license_path
      config
    end

    # Set a already-created Licensed Configuration object as the default
    # configuration
    def self.set_licensed_default!(licensed_configuration)
      DEFAULT_SEMAPHORE.synchronize do
        @config = licensed_configuration
      end
    end

    # @api private
    # @param config [net.sf.saxon.Configuration] The Saxon Configuration
    #   instance to wrap
    def initialize(config)
      @config = config
    end

    # Get a configuration option value
    #
    # See {net.sf.saxon.lib.FeatureKeys} for details of the available options.
    # Use the constant name as a string or symbol as the option, e.g.
    # +:allow_multhreading+, +'ALLOW_MULTITHREADING'+, +'allow_multithreading'+.
    #
    # @param option [String, Symbol]
    # @return [Object] the value of the configuration option
    # @raise [NameError] if the option name does not exist
    # @see net.sf.saxon.lib.FeatureKeys
    def [](option)
      feature = Feature.by_name(option)
      feature.get(@config)
    end

    # Set a configuration option value. See {#[]} for details about the option
    # names.
    #
    # @see #[]
    # @param option [String, Symbol]
    # @param value [Object] the value of the configuration option
    # @return [Object] the value you passed in
    # @raise [NameError] if the option name does not exist
    def []=(option, value)
      feature = Feature.get(option)
      feature.set(@config, value)
    end

    # Return the current ParseOptions object
    # See https://www.saxonica.com/documentation/index.html#!javadoc/net.sf.saxon.lib/ParseOptions
    # for details. This allows you to set JAXP features and properties to be
    # passed to the parser
    #
    # @return [Saxon::ParseOptions] the ParseOptions object
    def parse_options
      ParseOptions.new(@config.getParseOptions)
    end

    # @return [net.sf.saxon.Configuration] The underlying Saxon Configuration
    def to_java
      @config
    end

    private

    def normalize_option_name(option)
      option.to_s.downcase.to_sym
    end
  end
end
