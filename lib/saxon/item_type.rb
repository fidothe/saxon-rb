require_relative 's9api'

module Saxon
  # Represent XDM types abstractly
  class ItemType
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
      'Float' => :FLOAT,
      'Numeric' => :NUMERIC
    }.freeze

    # A mapping of type names/QNames to XDM type constants
    STR_MAPPING = {
      'array(*)' => :ANY_ARRAY,
      'xs:anyAtomicType' => :ANY_ATOMIC_VALUE,
      'item()' => :ANY_ITEM,
      'map(*)' => :ANY_MAP,
      'node()' => :ANY_NODE,
      'xs:anyURI' => :ANY_URI,
      'xs:base64Binary' => :BASE64_BINARY,
      'xs:boolean' => :BOOLEAN,
      'xs:byte' => :BYTE,
      'xs:date' => :DATE,
      'xs:dateTime' => :DATE_TIME,
      'xs:dateTimeStamp' => :DATE_TIME_STAMP,
      'xs:dayTimeDuration' => :DAY_TIME_DURATION,
      'xs:decimal' => :DECIMAL,
      'xs:double' => :DOUBLE,
      'xs:duration' => :DURATION,
      'xs:ENTITY' => :ENTITY,
      'xs:float' => :FLOAT,
      'xs:gDay' => :G_DAY,
      'xs:gMonth' => :G_MONTH,
      'xs:gMonthDay' => :G_MONTH_DAY,
      'xs:gYear' => :G_YEAR,
      'xs:gYearMonth' => :G_YEAR_MONTH,
      'xs:hexBinary' => :HEX_BINARY,
      'xs:ID' => :ID,
      'xs:IDREF' => :IDREF,
      'xs:int' => :INT,
      'xs:integer' => :INTEGER,
      'xs:language' => :LANGUAGE,
      'xs:long' => :LONG,
      'xs:Name' => :NAME,
      'xs:NCName' => :NCNAME,
      'xs:negativeInteger' => :NEGATIVE_INTEGER,
      'xs:NMTOKEN' => :NMTOKEN,
      'xs:nonNegativeInteger' => :NON_NEGATIVE_INTEGER,
      'xs:nonPositiveInteger' => :NON_POSITIVE_INTEGER,
      'xs:normalizedString' => :NORMALIZED_STRING,
      'xs:NOTATION' => :NOTATION,
      'xs:numeric' => :NUMERIC,
      'xs:positiveInteger' => :POSITIVE_INTEGER,
      'xs:QName' => :QNAME,
      'xs:short' => :SHORT,
      'xs:string' => :STRING,
      'xs:time' => :TIME,
      'xs:token' => :TOKEN,
      'xs:unsignedByte' => :UNSIGNED_BYTE,
      'xs:unsignedInt' => :UNSIGNED_INT,
      'xs:unsignedLong' => :UNSIGNED_LONG,
      'xs:unsignedShort' => :UNSIGNED_SHORT,
      'xs:untypedAtomic' => :UNTYPED_ATOMIC,
      'xs:yearMonthDuration' => :YEAR_MONTH_DURATION
    }.freeze

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
      def get_type(arg)
        new(get_s9_type(arg))
      end

      private

      def get_s9_type(arg)
        case arg
        when Class
          get_s9_class_mapped_type(arg)
        when String
          get_s9_str_mapped_type(arg)
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
  end
end
