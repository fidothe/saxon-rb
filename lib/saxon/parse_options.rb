require 'saxon/s9api'

module Saxon
  # Wraps the <tt>net.sf.saxon.lib.ParseOptions</tt> class, which holds default
  # options to be passed to the parser
  class ParseOptions
    attr_reader :parse_options
    private :parse_options

    # @api private
    # @param parse_options [net.sf.saxon.lib.ParseOptions, nil] The Saxon
    #   ParseOptions instance to wrap
    def initialize(parse_options = nil)
      @parse_options = parse_options || Saxon::S9API::ParseOptions.new
    end

    # Provide hash-like access to SAX parser properties
    # @return [Saxon::ParseOptions::ParserProperties] the properties object
    def properties
      @properties ||= ParserProperties.new(parse_options)
    end

    # Provide hash-like access to SAX parser features
    # @return [Saxon::ParseOptions::ParserFeatures] the features object
    def features
      @features ||= ParserFeatures.new(parse_options)
    end
  end

  # Provides idiomatic access to parser properties
  class ParserProperties
    include Enumerable

    attr_reader :parse_options
    private :parse_options

    # @api private
    # @param [Saxon::ParseOptions] parse_options The ParseOptions object this
    #   belongs to
    def initialize(parse_options)
      @parse_options ||= parse_options
    end

    # @return [Hash] the currently-set properties as a (frozen) hash
    def to_h
      (parse_options.getParserProperties || {}).freeze
    end

    # Fetch the current value of a Parser Property
    #
    # @param [String, URI] uri The Parser Property URI to fetch
    # @return [Object] The current value of the property
    def [](uri)
      return nil if parse_options.getParserProperties.nil?
      parse_options.getParserProperty(uri)
    end

    # Set the value of a Parser Property
    #
    # @param [String, URI] uri The Parser Property URI to set
    # @param [Object] value The value to set the property to
    # @return [Object] The new value of the property
    def []=(uri, value)
      parse_options.addParserProperties(uri, value)
      self[uri]
    end

    # Iterate across each currently-set property, in the same way as a hash
    #
    # @yield [uri, value]
    # @yieldparam uri [String] The URI of the property as a String
    # @yieldparam value [Object] The value of the property
    def each(&block)
      to_h.each(&block)
    end
  end

  # Provides idiomatic access to parser properties
  class ParserFeatures
    include Enumerable

    attr_reader :parse_options
    private :parse_options

    # @api private
    # @param [Saxon::ParseOptions] parse_options The ParseOptions object this
    #   belongs to
    def initialize(parse_options)
      @parse_options ||= parse_options
    end

    # @return [Hash] the currently-set features as a (frozen) hash
    def to_h
      (parse_options.getParserFeatures || {}).freeze
    end

    # Fetch the current value of a Parser Feature
    #
    # @param [String, URI] uri The Parser Feature URI to fetch
    # @return [Boolean, nil] The current value of the feature, or nil if it's
    #   unset
    def [](uri)
      pf = parse_options.getParserFeatures
      return nil if pf.nil? || !pf.include?(uri)
      parse_options.getParserFeature(uri)
    end

    # Set the value of a Parser Feature
    #
    # @param [String, URI] uri The Parser Property URI to set
    # @param [Boolean] value The value to set the property to
    # @return [Boolean] The new value of the property
    def []=(uri, value)
      parse_options.addParserFeature(uri, value)
      self[uri]
    end

    # Iterate across each currently-set feature, in the same way as a hash
    #
    # @yield [uri, value]
    # @yieldparam uri [String] The URI of the feature as a String
    # @yieldparam value [Boolean] Whether the feature is on or off
    def each(&block)
      to_h.each(&block)
    end
  end
end
