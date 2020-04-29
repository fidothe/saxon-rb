require 'saxon/xdm'

module Saxon
  # Builds XDM objects from XML sources, for use in XSLT or for query and
  # access
  class DocumentBuilder
    # Provides a simple configuraion DSL for DocumentBuilders.
    # @see DocumentBuilder.create
    class ConfigurationDSL
      # @api private
      def self.define(document_builder, block)
        new(document_builder).instance_exec(&block)
      end

      # @api private
      def initialize(document_builder)
        @document_builder = document_builder
      end

      # Sets line numbering on or off
      #
      # @see DocumentBuilder#line_numbering=
      #
      # @param value [Boolean] on (true) or off (false)
      def line_numbering(value)
        @document_builder.line_numbering = value
      end

      # Sets the base URI of documents created using this instance.
      #
      # @see DocumentBuilder.base_uri=
      #
      # @param value [String, URI::File, URI::HTTP] The (absolute) base URI to use
      def base_uri(value)
        @document_builder.base_uri = value
      end

      # Sets the base URI of documents created using this instance.
      #
      # @see DocumentBuilder.base_uri=
      #
      # @param value [String, URI::File, URI::HTTP] The (absolute) base URI to use
      def whitespace_stripping_policy(value)
        @document_builder.whitespace_stripping_policy = value
      end

      # Sets the base URI of documents created using this instance.
      #
      # @see DocumentBuilder.base_uri=
      #
      # @param value [String, URI::File, URI::HTTP] The (absolute) base URI to use
      def dtd_validation(value)
        @document_builder.dtd_validation = value
      end
    end


    # Create a new DocumentBuilder that can be used to build new XML documents
    # with the passed-in {Saxon::Processor}. If a block is passed in it's
    # executed as a DSL for configuring the builder instance.
    #
    # @param processor [Saxon::Processor] the Processor
    # @yield An DocumentBuilder configuration DSL block
    # @return [Saxon::DocumentBuilder] the new instance
    def self.create(processor, &block)
      new(processor.to_java.newDocumentBuilder, &block)
    end

    attr_reader :s9_document_builder
    private :s9_document_builder

    # @api private
    # @param [net.sf.saxon.s9api.DocumentBuilder] s9_document_builder The
    #   Saxon DocumentBuilder instance to wrap
    def initialize(s9_document_builder, &block)
      @s9_document_builder = s9_document_builder
      if block_given?
        ConfigurationDSL.define(self, block)
      end
    end

    # Report whether documents created using this instance will keep track of
    # the line and column numbers of elements.
    #
    # @return [Boolean] whether line numbering will be tracked
    def line_numbering?
      s9_document_builder.isLineNumbering
    end


    # Switch tracking of line and column numbers for elements in documents
    # created by this instance on or off
    #
    # @see https://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/DocumentBuilder@setLineNumbering
    #
    # @param on_or_not [Boolean] whether or not to track line numbering
    def line_numbering=(on_or_not)
      s9_document_builder.setLineNumbering(on_or_not)
    end

    # Return the default base URI to be used when building documents using this
    # instance. This value will be ignored if the source being parsed has an
    # intrinsic base URI (e.g. a File).
    #
    # Returns +nil+ if no URI is set (the default).
    #
    # @return [nil, URI::File, URI::HTTP] the default base URI (or nil)
    def base_uri
      uri = s9_document_builder.getBaseURI
      uri.nil? ? uri : URI(uri.to_s)
    end

    # Set the base URI of documents created using this instance. This value will
    # be ignored if the source being parsed has an intrinsic base URI (e.g. a
    # File)
    #
    # @see https://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/DocumentBuilder@setBaseURI
    #
    # @param uri [String, URI::File, URI::HTTP] The (absolute) base URI to use
    def base_uri=(uri)
      s9_document_builder.setBaseURI(java.net.URI.new(uri.to_s))
    end

    # Return the Whitespace stripping policy for this instance. Returns one of
    # the standard policy names as a symbol, or the custom Java
    # WhitespaceStrippingPolicy if one was defined using
    # +#whitespace_stripping_policy = ->(qname) { ... }+. (See
    # {#whitespace_stripping_policy=} for more.)
    #
    # +:all+: All whitespace-only nodes will be discarded
    #
    # +:none+: No whitespace-only nodes will be discarded (the default if DTD or
    # schema validation is not in effect)
    #
    # +:ignorable+: Whitespace-only nodes inside elements defined as
    # element-only in the DTD or schema being used will be discarded (the
    # default if DTD or schema validation is in effect)
    #
    # +:unspecified+: the default, which in practice means :ignorable if DTD or
    # schema validation is in effect, and :none otherwise.
    #
    # @return [:all, :none, :ignorable, :unspecified, Proc]
    def whitespace_stripping_policy
      s9_policy = s9_document_builder.getWhitespaceStrippingPolicy
      case s9_policy
      when Saxon::S9API::WhitespaceStrippingPolicy::UNSPECIFIED
        :unspecified
      when Saxon::S9API::WhitespaceStrippingPolicy::NONE
        :none
      when Saxon::S9API::WhitespaceStrippingPolicy::IGNORABLE
        :ignorable
      when Saxon::S9API::WhitespaceStrippingPolicy::ALL
        :all
      else
        s9_policy
      end
    end

    # Set the whitespace stripping policy to be used for documents built with
    # this instance.
    #
    # Possible values are:
    #
    # * One of the standard policies, as a symbol (+:all+, +:none+,
    #   +:ignorable+, +:unspecified+, see {#whitespace_stripping_policy}).
    # * A Java +net.sf.saxon.s9api.WhitesapceStrippingPolicy+ instance
    # * A Proc/lambda that is handed an element name as a {Saxon::QName}, and
    #   should return true (if whitespace should be stripped for this element)
    #   or false (it should not).
    # @example
    #   whitespace_stripping_policy = ->(element_qname) {
    #     element_qname == Saxon::QName.clark("{http://example.org/}element-name")
    #   }
    #
    # @see https://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/DocumentBuilder@setWhitespaceStrippingPolicy
    # @see https://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/WhitespaceStrippingPolicy
    # @param policy [Symbol, Proc, Saxon::S9API::WhitespaceStrippingPolicy] the
    #   policy to use
    def whitespace_stripping_policy=(policy)
      case policy
      when :unspecified, :none, :ignorable, :all
        s9_policy = Saxon::S9API::WhitespaceStrippingPolicy.const_get(policy.to_s.upcase.to_sym)
      when Proc
        wrapped_policy = ->(s9_qname) {
          policy.call(Saxon::QName.new(s9_qname))
        }
        s9_policy = Saxon::S9API::WhitespaceStrippingPolicy.makeCustomPolicy(wrapped_policy)
      when Saxon::S9API::WhitespaceStrippingPolicy
        s9_policy = policy
      else
        raise InvalidWhitespaceStrippingPolicyError, "#{policy.inspect} is not one of the allowed Symbols, or a custom policy"
      end
      s9_document_builder.setWhitespaceStrippingPolicy(s9_policy)
    end

    # @return [Boolean] whether DTD Validation is enabled
    def dtd_validation?
      s9_document_builder.isDTDValidation
    end

    # Switches DTD validation on or off.
    #
    # It's important to note that DTD validation only applies to documents that
    # contain a +<!doctype>+, but switching DTD validation off doesn't stop the
    # XML parser Saxon uses from trying to retrieve the DTD that's referenced,
    # which can mean network requests. By default, the SAX parser Saxon uses
    # (Xerces) doesn't make use of XML catalogs, which causes problems when documents reference a DTD with a relative path as in:
    #   <!DOCTYPE root-element SYSTEM "example.dtd">
    # This can be controlled through a configuration option, however.
    #
    # @see https://www.saxonica.com/documentation9.9/index.html#!javadoc/net.sf.saxon.s9api/DocumentBuilder@setDTDValidation
    # @see https://www.saxonica.com/documentation9.9/index.html#!sourcedocs/controlling-parsing
    # @param on [Boolean] whether DTD Validation should be enabled
    def dtd_validation=(on)
      s9_document_builder.setDTDValidation(on)
    end

    # @param [Saxon::Source] source The Saxon::Source containing the source
    #   IO/string
    # @return [Saxon::XDM::Node] The Saxon::XDM::Node representing the root of the
    #   document tree
    def build(source)
      XDM::Node.new(s9_document_builder.build(source.to_java))
    end

    # @return [net.sf.saxon.s9api.DocumentBuilder] The underlying Java Saxon
    #   DocumentBuilder instance
    def to_java
      s9_document_builder
    end
  end

  # Error raised when someone tries to set an invalid whitespace stripping
  # policy on a {DocumentBuilder}
  class InvalidWhitespaceStrippingPolicyError < RuntimeError
  end
end
