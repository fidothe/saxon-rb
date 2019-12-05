require_relative 's9api'
require_relative 'qname'
require_relative 'item_type/lexical_string_conversion'
require_relative 'item_type/value_to_ruby'

module Saxon
  # Represent XDM types abstractly
  class ItemType
    # Error raised when a Ruby class has no equivalent XDM type to be converted
    # into
    class UnmappedRubyTypeError < StandardError
      def initialize(class_name)
        @class_name = class_name
      end

      def to_s
        "Ruby class <#{@class_name}> has no XDM type equivalent"
      end
    end

    # Error raise when an attempt to reify an <tt>xs:*</tt> type string is
    # made, but the type string doesn't match any of the built-in <tt>xs:*</tt>
    # types
    class UnmappedXSDTypeNameError < StandardError
      def initialize(type_str)
        @type_str = type_str
      end

      def to_s
        "'#{@type_str}' is not recognised as an XSD built-in type"
      end
    end

    class Factory
      DEFAULT_SEMAPHORE = Mutex.new

      attr_reader :processor

      def initialize(processor)
        @processor = processor
      end

      def s9_factory
        return @s9_factory if instance_variable_defined?(:@s9_factory)
        DEFAULT_SEMAPHORE.synchronize do
          @s9_factory = S9API::ItemTypeFactory.new(processor.to_java)
        end
      end
    end

    TYPE_CACHE_MUTEX = Mutex.new
    # A mapping of Ruby types to XDM type constants
    TYPE_MAPPING = {
      'String' => :STRING,
      'Array'  => :ANY_ARRAY,
      'Hash'   => :ANY_MAP,
      'TrueClass'  => :BOOLEAN,
      'FalseClass' => :BOOLEAN,
      'Date' => :DATE,
      'DateTime' => :DATE_TIME,
      'Time' => :DATE_TIME,
      'BigDecimal' => :DECIMAL,
      'Integer' => :INTEGER,
      'Fixnum' => :INTEGER, # Fixnum/Bignum needed for JRuby 9.1/Ruby 2.3
      'Bignum' => :INTEGER,
      'Float' => :FLOAT,
      'Numeric' => :NUMERIC
    }.freeze

    # A mapping of QNames to XDM type constants
    QNAME_MAPPING = Hash[{
      'anyAtomicType' => :ANY_ATOMIC_VALUE,
      'anyURI' => :ANY_URI,
      'base64Binary' => :BASE64_BINARY,
      'boolean' => :BOOLEAN,
      'byte' => :BYTE,
      'date' => :DATE,
      'dateTime' => :DATE_TIME,
      'dateTimeStamp' => :DATE_TIME_STAMP,
      'dayTimeDuration' => :DAY_TIME_DURATION,
      'decimal' => :DECIMAL,
      'double' => :DOUBLE,
      'duration' => :DURATION,
      'ENTITY' => :ENTITY,
      'float' => :FLOAT,
      'gDay' => :G_DAY,
      'gMonth' => :G_MONTH,
      'gMonthDay' => :G_MONTH_DAY,
      'gYear' => :G_YEAR,
      'gYearMonth' => :G_YEAR_MONTH,
      'hexBinary' => :HEX_BINARY,
      'ID' => :ID,
      'IDREF' => :IDREF,
      'int' => :INT,
      'integer' => :INTEGER,
      'language' => :LANGUAGE,
      'long' => :LONG,
      'Name' => :NAME,
      'NCName' => :NCNAME,
      'negativeInteger' => :NEGATIVE_INTEGER,
      'NMTOKEN' => :NMTOKEN,
      'nonNegativeInteger' => :NON_NEGATIVE_INTEGER,
      'nonPositiveInteger' => :NON_POSITIVE_INTEGER,
      'normalizedString' => :NORMALIZED_STRING,
      'NOTATION' => :NOTATION,
      'numeric' => :NUMERIC,
      'positiveInteger' => :POSITIVE_INTEGER,
      'QName' => :QNAME,
      'short' => :SHORT,
      'string' => :STRING,
      'time' => :TIME,
      'token' => :TOKEN,
      'unsignedByte' => :UNSIGNED_BYTE,
      'unsignedInt' => :UNSIGNED_INT,
      'unsignedLong' => :UNSIGNED_LONG,
      'unsignedShort' => :UNSIGNED_SHORT,
      'untypedAtomic' => :UNTYPED_ATOMIC,
      'yearMonthDuration' => :YEAR_MONTH_DURATION
    }.map { |local_name, constant|
      qname = Saxon::QName.create({
        prefix: 'xs', uri: 'http://www.w3.org/2001/XMLSchema',
        local_name: local_name
      })
      [qname, constant]
    }].freeze

    # A mapping of type names/QNames to XDM type constants
    STR_MAPPING = {
      'array(*)' => :ANY_ARRAY,
      'item()' => :ANY_ITEM,
      'map(*)' => :ANY_MAP,
      'node()' => :ANY_NODE
    }.merge(
      Hash[QNAME_MAPPING.map { |qname, v| [qname.to_s, v] }]
    ).freeze

    ATOMIC_VALUE_LEXICAL_STRING_CONVERTORS = Hash[
      LexicalStringConversion::Convertors.constants.map { |const|
        [S9API::ItemType.const_get(const), LexicalStringConversion::Convertors.const_get(const)]
      }
    ].freeze

    ATOMIC_VALUE_TO_RUBY_CONVERTORS = Hash[
      ValueToRuby::Convertors.constants.map { |const|
        [S9API::ItemType.const_get(const), ValueToRuby::Convertors.const_get(const)]
      }
    ].freeze

    class << self
      # Get an appropriate {ItemType} for a Ruby type or given a type name as a
      # string
      #
      # @return [Saxon::ItemType]
      # @overload get_type(ruby_class)
      #   Get an appropriate {ItemType} for object of a given Ruby class
      #   @param ruby_class [Class] The Ruby class to get a type for
      # @overload get_type(type_name)
      #   Get the {ItemType} for the name
      #   @param type_name [String] name of the built-in {ItemType} to fetch
      #   (e.g. +xs:string+ or +element()+)
      # @overload get_type(item_type)
      #   Given an instance of {ItemType}, simply return the instance
      #   @param item_type [Saxon::ItemType] an existing ItemType instance
      def get_type(arg)
        case arg
        when Saxon::ItemType
          arg
        else
          fetch_type_instance(get_s9_type(arg))
        end
      end

      private

      def fetch_type_instance(s9_type)
        TYPE_CACHE_MUTEX.synchronize do
          @type_instance_cache = {} if !instance_variable_defined?(:@type_instance_cache)
          if type_instance = @type_instance_cache[s9_type]
            type_instance
          else
            @type_instance_cache[s9_type] = new(s9_type)
          end
        end
      end

      def get_s9_type(arg)
        case arg
        when S9API::ItemType
          arg
        when Saxon::QName
          get_s9_qname_mapped_type(arg)
        when Class
          get_s9_class_mapped_type(arg)
        when String
          get_s9_str_mapped_type(arg)
        end
      end

      def get_s9_qname_mapped_type(qname)
        if mapped_type = QNAME_MAPPING.fetch(qname, false)
          S9API::ItemType.const_get(mapped_type)
        else
          raise UnmappedXSDTypeNameError, qname.to_s
        end
      end

      def get_s9_class_mapped_type(klass)
        class_name = klass.name
        if mapped_type = TYPE_MAPPING.fetch(class_name, false)
          S9API::ItemType.const_get(mapped_type)
        else
          raise UnmappedRubyTypeError, class_name
        end
      end

      def get_s9_str_mapped_type(type_str)
        if mapped_type = STR_MAPPING.fetch(type_str, false)
          # ANY_ITEM is a method, not a constant, for reasons not entirely
          # clear to me
          return S9API::ItemType.ANY_ITEM if mapped_type == :ANY_ITEM
          S9API::ItemType.const_get(mapped_type)
        else
          raise UnmappedXSDTypeNameError, type_str
        end
      end
    end

    attr_reader :s9_item_type
    private :s9_item_type

    # @api private
    def initialize(s9_item_type)
      @s9_item_type = s9_item_type
    end

    # Return the {QName} which represents this type
    #
    # @return [Saxon::QName] the {QName} of the type
    def type_name
      @type_name ||= Saxon::QName.new(s9_item_type.getTypeName)
    end

    # @return [Saxon::S9API::ItemType] The underlying Saxon Java ItemType object
    def to_java
      s9_item_type
    end

    # compares two {ItemType}s using the underlying Saxon and XDM comparision rules
    # @param other [Saxon::ItemType]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(ItemType)
      s9_item_type.equals(other.to_java)
    end

    alias_method :eql?, :==

    def hash
      @hash ||= s9_item_type.hashCode
    end

    # Generate the appropriate lexical string representation of the value
    # given the ItemType's schema definition.
    #
    # Types with no explcit formatter defined just get to_s called on them...
    #
    # @param value [Object] The Ruby value to generate the lexical string
    #   representation of
    # @return [String] The XML Schema-defined lexical string representation of
    #   the value
    def lexical_string(value)
      lexical_string_convertor.call(value, self)
    end

    # Convert an XDM Atomic Value to an instance of an appropriate Ruby class, or return the lexical string.
    #
    # It's assumed that the XDM::AtomicValue is of this type, otherwise an error is raised.
    # @param xdm_atomic_value [Saxon::XDM::AtomicValue] The XDM atomic value to be converted.
    def ruby_value(xdm_atomic_value)
      value_to_ruby_convertor.call(xdm_atomic_value)
    end

    private

    def lexical_string_convertor
      @lexical_string_convertor ||= ATOMIC_VALUE_LEXICAL_STRING_CONVERTORS.fetch(s9_item_type, ->(value, item) { value.to_s })
    end

    def value_to_ruby_convertor
      @value_to_ruby_convertor ||= ATOMIC_VALUE_TO_RUBY_CONVERTORS.fetch(s9_item_type, ->(xdm_atomic_value) {
        xdm_atomic_value.to_s
      })
    end
  end
end
