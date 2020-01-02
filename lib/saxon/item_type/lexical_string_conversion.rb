require 'bigdecimal'

module Saxon
  class ItemType
    # A collection of lamba-like objects for converting Ruby values into
    # lexical strings for specific XSD datatypes
    module LexicalStringConversion
      # Simple validation helper that checks if a value string matches an
      # allowed lexical string pattern space or not.
      #
      # @param value [Object] the value whose to_s representation should be
      #   checked
      # @param item_type [Saxon::ItemType] the ItemType whose lexical pattern
      #   space should be checked against
      # @param pattern [Regexp] the lexical pattern space Regexp to use in the
      #   checking
      # @return [String] the lexical string for the value and type
      # @raise [Errors::BadRubyValue] if the ruby value doesn't produce a string
      #   which validates against the allowed pattern
      def self.validate(value, item_type, pattern)
        str = value.to_s
        raise Errors::BadRubyValue.new(value, item_type) if str.match(pattern).nil?
        str
      end

      # Helper class for performing conversion and validation to XDM integer
      # types from Ruby's Fixnum/Bignum/Integer classes
      class IntegerConversion
        attr_reader :min, :max

        def initialize(min, max)
          @min, @max = min, max
        end

        # Returns whether the Ruby integer is within the range allowed for the
        # XDM type
        # @param integer_value [Integer] the ruby integer to check
        # @return [Boolean] whether the value is within bounds
        def in_bounds?(integer_value)
          gte_min?(integer_value) && lte_max?(integer_value)
        end

        # Returns whether the Ruby integer is >= the lower bound of the range
        # allowed for the XDM type
        # @param integer_value [Integer] the ruby integer to check
        # @return [Boolean] whether the value is okay
        def gte_min?(integer_value)
          return true if min.nil?
          integer_value >= min
        end

        # Returns whether the Ruby integer is <= the upper bound of the range
        # allowed for the XDM type
        # @param integer_value [Integer] the ruby integer to check
        # @return [Boolean] whether the value is okay
        def lte_max?(integer_value)
          return true if max.nil?
          integer_value <= max
        end

        # Check a value against our type constraints, and return the lexical
        # string representation if it's okay.
        #
        # @param value [Integer] the ruby value
        # @param item_type [Saxon::ItemType] the item type
        # @return [String] the lexical string representation of the value
        # @raise [Errors::RubyValueOutOfBounds] if the value is outside the
        #   type's permitted bounds
        def call(value, item_type)
          integer_value = case value
          when ::Numeric
            value.to_i
          else
            Integer(LexicalStringConversion.validate(value, item_type, Patterns::INTEGER), 10)
          end
          raise Errors::RubyValueOutOfBounds.new(value, item_type) unless in_bounds?(integer_value)
          integer_value.to_s
        end
      end

      # Helper class for performing conversion and validation to XDM
      # Floating-point types from Ruby's Float class
      class FloatConversion
        def initialize(size = :double)
          @double = size == :double
        end

        # Check a value against our type constraints, and return the lexical
        # string representation if it's okay.
        #
        # @param value [Float] the ruby value
        # @param item_type [Saxon::ItemType] the item type
        # @return [String] the lexical string representation of the value
        def call(value, item_type)
          case value
          when ::Float::INFINITY
            'INF'
          when -::Float::INFINITY
            '-INF'
          when Numeric
            float_value(value).to_s
          else
            LexicalStringConversion.validate(value, item_type, Patterns::FLOAT)
          end
        end

        private

        # Is this a double-precision XDM float?
        # @return [Boolean] true if we're converting a double-precision float
        def double?
          @double
        end

        # Return the float as either a double-precision or single-precision
        # float as needed
        def float_value(float_value)
          return float_value if double?
          convert_to_single_precision(float_value)
        end

        def convert_to_single_precision(float_value)
          [float_value].pack('f').unpack('f').first
        end
      end

      # Convert a value in seconds into an XDM Duration string
      class DurationConversion
        attr_reader :pattern

        def initialize(pattern)
          @pattern = pattern
        end

        # Produce a lexical Duration string from a numeric Ruby value
        # representing seconds
        def call(value, item_type)
          return numeric(value) if Numeric === value
          LexicalStringConversion.validate(value, item_type, pattern)
        end

        private

        def numeric(value)
          sign = value.negative? ? '-' : ''
          case value
          when Integer
            "#{sign}PT#{value.abs}S"
          when BigDecimal
            "#{sign}PT#{value.abs.to_s('F')}S"
          else
            sprintf("%sPT%0.9fS", sign, value.abs)
          end
        end
      end

      # Helper class for creating convertors for the various G* Date-related
      # types that allow single values (GDay, GMonth, GYear).
      class GDateConversion
        attr_reader :bounds, :integer_formatter, :validation_pattern

      # @param args [Hash]
      # @option args [Range] :bounds the integer bounds for values of this type
      # @option args [Regexp] :validation_pattern the pattern used to validate the
      #   value when it's a String not an Integer
      # @option args [Proc] :integer_formatter a proc/lambda that will produce a
      #   correctly-formatted lexical string from an Integer value
      def initialize(args = {})
          @bounds = args.fetch(:bounds)
          @validation_pattern = args.fetch(:validation_pattern)
          @integer_formatter = args.fetch(:integer_formatter)
        end

        # @param value [String, Integer] the value to convert
        # @param item_type [XDM::ItemType] the type being converted to
        # @return [String] a correctly formatted String
        def call(value, item_type)
          case value
          when Integer
            check_value_bounds!(value, item_type)
            sprintf(integer_formatter.call(value), value)
          else
            formatted_value = LexicalStringConversion.validate(value, item_type, validation_pattern)
            extract_and_check_value_bounds!(formatted_value, item_type)
            formatted_value
          end
        end

        private

        def extract_value_from_validated_format(formatted_value)
          Integer(formatted_value.gsub(validation_pattern, '\1'), 10)
        end

        def check_value_bounds!(value, item_type)
          bounds_method = bounds.respond_to?(:include?) ? :include? : :call
          raise Errors::RubyValueOutOfBounds.new(value, item_type) unless bounds.send(bounds_method, value)
        end

        def extract_and_check_value_bounds!(formatted_value, item_type)
          check_value_bounds!(extract_value_from_validated_format(formatted_value), item_type)
        end
      end

      # Convert Bytes. Idiomatically, Ruby uses +ASCII_8BIT+ encoded strings to
      # represent bytes, and so a single character represents a single byte. XDM
      # uses the decimal value of a signed or unsigned 8 bit integer
      class ByteConversion
        attr_reader :unpack_format

        def initialize(kind = :signed)
          @unpack_format = kind == :unsigned ? 'C' : 'c'
        end

        def call(value, item_type)
          raise Errors::RubyValueOutOfBounds.new(value, item_type) if value.bytesize != 1
          value = value.to_s.force_encoding(Encoding::ASCII_8BIT)
          value.unpack(unpack_format).first.to_s
        end
      end

      # Pattern fragments that can be combined to help create the lexical space
      # patterns in {Patterns}
      module PatternFragments
        TIME_DURATION = /(?:T
          (?:
            # The time part of the format allows T0H1M1S, T1H1M, T1M1S, T1H1S, T1H, T1M, T1S
            [0-9]+[HM]|
            [0-9]+(?:\.[0-9]+)?S|
            [0-9]+H[0-9]+M|
            [0-9]+H[0-9]+(?:\.[0-9]+)?S|
            [0-9]+M[0-9]+(?:\.[0-9]+)?S|
            [0-9]+H[0-9]+M[0-9]+(?:\.[0-9]+)?S
          )
        )?/x
        DATE = /-?[0-9]{4}-[0-9]{2}-[0-9]{2}/
        TIME = /[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?/
        TIME_ZONE = /(?:[\-+][0-9]{2}:[0-9]{2}|Z)?/
        NCNAME_START_CHAR = '[A-Z]|_|[a-z]|[\u{C0}-\u{D6}]|[\u{D8}-\u{F6}]|[\u{F8}-\u{2FF}]|[\u{370}-\u{37D}]|[\u{37F}-\u{1FFF}]|[\u{200C}-\u{200D}]|[\u{2070}-\u{218F}]|[\u{2C00}-\u{2FEF}]|[\u{3001}-\u{D7FF}]|[\u{F900}-\u{FDCF}]|[\u{FDF0}-\u{FFFD}]|[\u{10000}-\u{EFFFF}]'
        NAME_START_CHAR = ":|" + NCNAME_START_CHAR
        NCNAME_CHAR = NCNAME_START_CHAR + '|-|\.|[0-9]|\u{B7}|[\u{0300}-\u{036F}]|[\u{203F}-\u{2040}]'
        NAME_CHAR = ":|" + NCNAME_CHAR
      end

      # A collection of lexical space patterns for XDM types
      module Patterns
        def self.build(*patterns)
          Regexp.new((['\A'] + patterns.map(&:to_s) + ['\z']).join(''))
        end
        DATE = build(PatternFragments::DATE, PatternFragments::TIME_ZONE)
        DATE_TIME = build(PatternFragments::DATE, 'T', PatternFragments::TIME, PatternFragments::TIME_ZONE)
        TIME = build(PatternFragments::TIME, PatternFragments::TIME_ZONE)
        DURATION = build(/-?P(?!\z)(?:[0-9]+Y)?(?:[0-9]+M)?(?:[0-9]+D)?/, PatternFragments::TIME_DURATION)
        DAY_TIME_DURATION = build(/-?P(?!\z)(?:[0-9]+D)?/, PatternFragments::TIME_DURATION)
        YEAR_MONTH_DURATION = /\A-?P(?!\z)(?:[0-9]+Y)?(?:[0-9]+M)?\z/
        G_DAY = build(/---([0-9]{2})/, PatternFragments::TIME_ZONE)
        G_MONTH = build(/--([0-9]{2})/, PatternFragments::TIME_ZONE)
        G_YEAR = build(/(-?[0-9]{4,})/, PatternFragments::TIME_ZONE)
        G_YEAR_MONTH = build(/-?([0-9]{4,})-([0-9]{2})/, PatternFragments::TIME_ZONE)
        G_MONTH_DAY = build(/--([0-9]{2})-([0-9]{2})/, PatternFragments::TIME_ZONE)
        INTEGER = /\A[+-]?[0-9]+\z/
        DECIMAL = /\A[+-]?[0-9]+(?:\.[0-9]+)?\z/
        FLOAT = /\A(?:[+-]?[0-9]+(?:\.[0-9]+)?(?:[eE][0-9]+)?|-?INF|NaN)\z/
        NCNAME = build("(?:#{PatternFragments::NCNAME_START_CHAR})", "(?:#{PatternFragments::NCNAME_CHAR})*")
        NAME = build("(?:#{PatternFragments::NAME_START_CHAR})", "(?:#{PatternFragments::NAME_CHAR})*")
        TOKEN = /\A[^\u0020\u000A\u000D\u0009]+(?: [^\u0020\u000A\u000D\u0009]+)*\z/
        NORMALIZED_STRING = /\A[^\u000A\u000D\u0009]+\z/
        NMTOKEN = build("(?:#{PatternFragments::NAME_CHAR})+")
        LANGUAGE = /\A[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*\z/
        BASE64_BINARY = /\A(?:(?:[A-Za-z0-9+\/] ?){4})*(?:(?:[A-Za-z0-9+\/] ?){3}[A-Za-z0-9+\/]|(?:[A-Za-z0-9+\/] ?){2}[AEIMQUYcgkosw048] ?=|[A-Za-z0-9+\/] ?[AQgw] ?= ?=)?\z/
      end

      # Convertors from Ruby values to lexical string representations for a
      # particular XDM type
      module Convertors
        ANY_URI = ->(value, item_type) {
          uri_classes = [URI::Generic]
          case value
          when URI::Generic
            value.to_s
          else
            begin
              URI(value.to_s).to_s
            rescue URI::InvalidURIError
              raise Errors::BadRubyValue.new(value, item_type)
            end
          end
        }
        BASE64_BINARY = ->(value, item_type) {
          Base64.strict_encode64(value.to_s.force_encoding(Encoding::ASCII_8BIT))
        }
        BOOLEAN = ->(value, item_type) {
          value ? 'true' : 'false'
        }
        BYTE = ByteConversion.new
        DATE = ->(value, item_type) {
          if value.respond_to?(:strftime)
            value.strftime('%F')
          else
            LexicalStringConversion.validate(value, item_type, Patterns::DATE)
          end
        }
        DATE_TIME = ->(value, item_type) {
          if value.respond_to?(:strftime)
            value.strftime('%FT%T%:z')
          else
            LexicalStringConversion.validate(value, item_type, Patterns::DATE_TIME)
          end
        }
        TIME = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::TIME)
        }
        DATE_TIME_STAMP = DATE_TIME
        DAY_TIME_DURATION = DurationConversion.new(Patterns::DAY_TIME_DURATION)
        DECIMAL = ->(value, item_type) {
          case value
          when ::Integer
            value.to_s
          when ::BigDecimal
            value.to_s('F')
          when ::Float
            BigDecimal(value, ::Float::DIG).to_s('F')
          else
            LexicalStringConversion.validate(value, item_type, Patterns::DECIMAL)
          end
        }
        DOUBLE = FloatConversion.new(:single)
        DURATION = DurationConversion.new(Patterns::DURATION)
        FLOAT = FloatConversion.new
        G_DAY = GDateConversion.new({
          bounds: 1..31,
          validation_pattern: Patterns::G_DAY,
          integer_formatter: ->(value) { '---%02d' }
        })
        G_MONTH = GDateConversion.new({
          bounds: 1..12,
          validation_pattern: Patterns::G_MONTH,
          integer_formatter: ->(value) { '--%02d' }
        })
        G_MONTH_DAY = ->(value, item_type) {
          month_days = {
             1 => 31,
             2 => 29,
             3 => 31,
             4 => 30,
             5 => 31,
             6 => 30,
             7 => 31,
             8 => 31,
             9 => 30,
            10 => 31,
            11 => 30,
            12 => 31
          }
          formatted_value = LexicalStringConversion.validate(value, item_type, Patterns::G_MONTH_DAY)
          month, day = Patterns::G_MONTH_DAY.match(formatted_value).captures.take(2).map { |i|
            Integer(i, 10)
          }
          raise Errors::RubyValueOutOfBounds.new(value, item_type) if day > month_days[month]
          formatted_value
        }
        G_YEAR = GDateConversion.new({
          bounds: ->(value) { value != 0 },
          validation_pattern: Patterns::G_YEAR,
          integer_formatter: ->(value) {
            value.negative? ? '%05d' : '%04d'
          }
        })
        G_YEAR_MONTH = ->(value, item_type) {
          formatted_value = LexicalStringConversion.validate(value, item_type, Patterns::G_YEAR_MONTH)
          year, month = Patterns::G_YEAR_MONTH.match(formatted_value).captures.take(2).map { |i|
            Integer(i, 10)
          }
          if year == 0 || !(1..12).include?(month)
            raise Errors::RubyValueOutOfBounds.new(value, item_type)
          end
          value
        }
        HEX_BINARY = ->(value, item_type) {
          value.to_s.force_encoding(Encoding::ASCII_8BIT).each_byte.map { |b| b.to_s(16) }.join
        }
        INT = IntegerConversion.new(-2147483648, 2147483647)
        INTEGER = IntegerConversion.new(nil, nil)
        LANGUAGE = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::LANGUAGE)
        }
        LONG = IntegerConversion.new(-9223372036854775808, 9223372036854775807)
        NAME = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::NAME)
        }
        ID = IDREF = ENTITY = NCNAME = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::NCNAME)
        }
        NEGATIVE_INTEGER = IntegerConversion.new(nil, -1)
        NMTOKEN = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::NMTOKEN)
        }
        NON_NEGATIVE_INTEGER = IntegerConversion.new(0, nil)
        NON_POSITIVE_INTEGER = IntegerConversion.new(nil, 0)
        NORMALIZED_STRING = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::NORMALIZED_STRING)
        }
        POSITIVE_INTEGER = IntegerConversion.new(1, nil)
        SHORT = IntegerConversion.new(-32768, 32767)
        # STRING (It's questionable whether anything needs doing here)
        TOKEN = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::TOKEN)
        }
        UNSIGNED_BYTE = ByteConversion.new(:unsigned)
        UNSIGNED_INT = IntegerConversion.new(0, 4294967295)
        UNSIGNED_LONG = IntegerConversion.new(0, 18446744073709551615)
        UNSIGNED_SHORT = IntegerConversion.new(0, 65535)
        YEAR_MONTH_DURATION = ->(value, item_type) {
          LexicalStringConversion.validate(value, item_type, Patterns::YEAR_MONTH_DURATION)
        }
        QNAME = NOTATION = ->(value, item_type) {
          raise Errors::UnconvertableNamespaceSensitveItemType
        }
      end

      # Conversion process error classes
      module Errors
        # Raised during conversion from Ruby value to XDM Type lexical string
        # when the ruby value does not conform to the Type's string
        # representation.
        class BadRubyValue < ArgumentError
          attr_reader :value, :item_type

          def initialize(value, item_type)
            @value, @item_type = value, item_type
          end

          def to_s
            "Ruby value #{value.inspect} cannot be converted to an XDM #{item_type.type_name.to_s}"
          end
        end

        # Raised during conversion from Ruby value to XDM type lexical string
        # when the ruby value fits the Type's string representation, but is out
        # of the permitted bounds for the type, for instance an integer bigger
        # than <tt>32767</tt> for the type <tt>xs:short</tt>
        class RubyValueOutOfBounds < ArgumentError
          attr_reader :value, :item_type

          def initialize(value, item_type)
            @value, @item_type = value, item_type
          end

          def to_s
            "Ruby value #{value.inspect} is outside the allowed bounds of an XDM #{item_type.type_name.to_s}"
          end
        end

        # Raised during conversion from Ruby value to XDM type if the XDM type
        # is one of the namespace-sensitive types that cannot be created from a
        # lexical string
        class UnconvertableNamespaceSensitveItemType < Exception; end
      end
    end
  end
end
