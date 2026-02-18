require 'saxon/s9api'

module Saxon
  # Wraps the <tt>net.sf.saxon.lib.ParseOptions</tt> class, which holds default
  # options to be passed to the parser. This is an immutable class, so all
  # mnodifications result in new instances and we provide a block-based creation dsl
  class ParseOptions
    attr_reader :parse_options
    private :parse_options

    def self.create(&block)
      dsl = DSL.new(Saxon::S9API::ParseOptions.new)
      new(dsl.build(block))
    end

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

    class DSL
      attr_reader :s9_parse_options
      private :s9_parse_options
      def initialize(s9_parse_options)
        @s9_parse_options = s9_parse_options
      end

      def build(block)
        instance_exec(&block)
        s9_parse_options
      end

      # Set the values of Parser Properties using a hash
      #
      # @param Hash{String, URI => Object} properties The properties to set as a Hash of URI to Value
      def properties(properties)
        @s9_parse_options = properties.inject(s9_parse_options)  { |s9_parse_options, kv|
          uri, value = kv
          s9_parse_options.withParserProperty(uri, value)
        }
      end

      # Set the values of Parser Features using a hash
      #
      # @param Hash{String, URI => Boolean} features The parser features to set as a Hash of URI to Value
      def features(features)
        @s9_parse_options = features.inject(s9_parse_options)  { |s9_parse_options, kv|
          uri, value = kv
          s9_parse_options.withParserFeature(uri, value)
        }
      end
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

    # Fetch the current state of a Parser Feature
    #
    # @param [String, URI] uri The Parser Feature URI to fetch
    # @return [Boolean] The current value of the feature, or nil if it's
    #   unset
    def [](uri)
      pf = parse_options.getParserFeatures
      return nil if pf.nil? || !pf.include?(uri)
      parse_options.hasParserFeature(uri)
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
