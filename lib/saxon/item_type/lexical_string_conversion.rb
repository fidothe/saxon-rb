require 'bigdecimal'

module Saxon
  class ItemType
    # A collection of lamba-like objects for converting Ruby values into
    # lexical strings for specific XSD datatypes
    module LexicalStringConversion
      def self.validate(value, pattern)
        str = value.to_s
        raise Errors::BadRubyValue unless str.match?(pattern)
        str
      end

      class IntegerConversion
        attr_reader :min, :max

        def initialize(min, max)
          @min, @max = min, max
        end

        def in_bounds?(integer_value)
          gte_min?(integer_value) && lte_max?(integer_value)
        end

        def gte_min?(integer_value)
          return true if min.nil?
          integer_value >= min
        end

        def lte_max?(integer_value)
          return true if max.nil?
          integer_value <= max
        end

        def call(value)
          integer_value = case value
          when ::Numeric
            value.to_i
          else
            Integer(LexicalStringConversion.validate(value, Patterns::INTEGER), 10)
          end
          raise Errors::RubyValueOutOfBounds unless in_bounds?(integer_value)
          integer_value.to_s
        end
      end

      class FloatConversion
        def initialize(size = :double)
          @double = size == :double
        end

        def double?
          @double
        end

        def float_value(float_value)
          return float_value if double?
          convert_to_single_precision(float_value)
        end

        def convert_to_single_precision(float_value)
          [float_value].pack('f').unpack('f').first
        end

        def call(value)
          case value
          when ::Float::INFINITY
            'INF'
          when -::Float::INFINITY
            '-INF'
          when Numeric
            float_value(value).to_s
          else
            LexicalStringConversion.validate(value, Patterns::FLOAT)
          end
        end
      end

      class GDateConversion
        attr_reader :bounds, :integer_formatter, :validation_pattern

        def initialize(args = {})
          @bounds = args.fetch(:bounds)
          @validation_pattern = args.fetch(:validation_pattern)
          @integer_formatter = args.fetch(:integer_formatter)
        end

        def extract_value_from_validated_format(formatted_value)
          Integer(formatted_value.gsub(validation_pattern, '\1'), 10)
        end

        def check_value_bounds!(value)
          bounds_method = bounds.respond_to?(:include?) ? :include? : :call
          raise Errors::RubyValueOutOfBounds unless bounds.send(bounds_method, value)
        end

        def extract_and_check_value_bounds!(formatted_value)
          check_value_bounds!(extract_value_from_validated_format(formatted_value))
        end

        def call(value)
          case value
          when Integer
            check_value_bounds!(value)
            sprintf(integer_formatter.call(value), value)
          else
            formatted_value = LexicalStringConversion.validate(value, validation_pattern)
            extract_and_check_value_bounds!(formatted_value)
            formatted_value
          end
        end
      end

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
        TIME_ZONE = /(?:[\-+][0-9]{2}:[0-9]{2}|Z)?/
      end

      module Patterns
        def self.build(*patterns)
          Regexp.new((['\A'] + patterns.map(&:to_s) + ['\z']).join(''))
        end
        DATE = build(/-?[0-9]{4}-[0-9]{2}-[0-9]{2}/, PatternFragments::TIME_ZONE)
        DATETIME = build(/-?[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?/, PatternFragments::TIME_ZONE)
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
        FLOAT = /\A(?:[+-]?[0-9]+(?:\.[0-9]+)?(?:[eE][0-9]+)|-?INF|NaN)\z/
      end

      module Convertors
        # :ANY_ATOMIC_VALUE,
        # :ANY_URI,
        # :BASE64_BINARY,
        # :BOOLEAN,
        # :BYTE,
        DATE = ->(value) {
          if value.respond_to?(:strftime)
            value.strftime('%F')
          else
            LexicalStringConversion.validate(value, Patterns::DATE)
          end
        }
        DATE_TIME = ->(value) {
          if value.respond_to?(:strftime)
            value.strftime('%FT%T%:z')
          else
            LexicalStringConversion.validate(value, Patterns::DATETIME)
          end
        }
        DATE_TIME_STAMP = DATE_TIME
        DAY_TIME_DURATION = ->(value) {
          case value
          when Integer
            sign = value.negative? ? '-' : ''
            "#{sign}PT#{value.abs}S"
          when BigDecimal
            sign = value.negative? ? '-' : ''
            "#{sign}PT#{value.abs.to_s('F')}S"
          when Numeric
            sign = value.negative? ? '-' : ''
            sprintf("%sPT%0.9fS", sign, value.abs)
          else
            LexicalStringConversion.validate(value, Patterns::DAY_TIME_DURATION)
          end
        }
        DECIMAL = -> (value) {
          case value
          when ::Integer
            value.to_s
          when ::BigDecimal
            value.to_s('F')
          when ::Float
            BigDecimal(value, ::Float::DIG).to_s('F')
          else
            LexicalStringConversion.validate(value, Patterns::DECIMAL)
          end
        }
        DOUBLE = FloatConversion.new(:single)
        DURATION = ->(value) {
          case value
          when Integer
            sign = value.negative? ? '-' : ''
            "#{sign}PT#{value.abs}S"
          when BigDecimal
            sign = value.negative? ? '-' : ''
            "#{sign}PT#{value.abs.to_s('F')}S"
          when Numeric
            sign = value.negative? ? '-' : ''
            sprintf("%sPT%0.9fS", sign, value.abs)
          else
            LexicalStringConversion.validate(value, Patterns::DURATION)
          end
        }
        # :ENTITY,
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
        G_MONTH_DAY = ->(value) {
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
          formatted_value = LexicalStringConversion.validate(value, Patterns::G_MONTH_DAY)
          month, day = Patterns::G_MONTH_DAY.match(formatted_value).captures.take(2).map { |i|
            Integer(i, 10)
          }
          raise Errors::RubyValueOutOfBounds if day > month_days[month]
          formatted_value
        }
        G_YEAR = GDateConversion.new({
          bounds: ->(value) { value != 0 },
          validation_pattern: Patterns::G_YEAR,
          integer_formatter: ->(value) {
            value.negative? ? '%05d' : '%04d'
          }
        })
        G_YEAR_MONTH = ->(value) {
          formatted_value = LexicalStringConversion.validate(value, Patterns::G_YEAR_MONTH)
          year, month = Patterns::G_YEAR_MONTH.match(formatted_value).captures.take(2).map { |i|
            Integer(i, 10)
          }
          if year == 0 || !(1..12).include?(month)
            raise Errors::RubyValueOutOfBounds
          end
          value
        }
        # :HEX_BINARY,
        # :ID,
        # :IDREF,
        INT = IntegerConversion.new(-2147483648, 2147483647)
        INTEGER = IntegerConversion.new(nil, nil)
        # :LANGUAGE,
        LONG = IntegerConversion.new(-9223372036854775808, 9223372036854775807)
        # :NAME,
        # :NCNAME,
        NEGATIVE_INTEGER = IntegerConversion.new(nil, -1)
        # :NMTOKEN,
        NON_NEGATIVE_INTEGER = IntegerConversion.new(0, nil)
        NON_POSITIVE_INTEGER = IntegerConversion.new(nil, 0)
        # :NORMALIZED_STRING,
        # :NOTATION,
        POSITIVE_INTEGER = IntegerConversion.new(1, nil)
        # :QNAME,
        SHORT = IntegerConversion.new(-32768, 32767)
        # :STRING,
        # :TIME,
        # :TOKEN,
        # :UNSIGNED_BYTE,
        UNSIGNED_INT = IntegerConversion.new(0, 4294967295)
        UNSIGNED_LONG = IntegerConversion.new(0, 18446744073709551615)
        UNSIGNED_SHORT = IntegerConversion.new(0, 65535)
        # :UNTYPED_ATOMIC,
        YEAR_MONTH_DURATION = ->(value) {
          LexicalStringConversion.validate(value, Patterns::YEAR_MONTH_DURATION)
        }
      end

      module Errors
        class BadRubyValue < ArgumentError; end
        class RubyValueOutOfBounds < ArgumentError; end
      end
    end
  end
end
