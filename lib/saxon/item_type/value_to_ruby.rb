require 'bigdecimal'

module Saxon
  class ItemType
    # A collection of lamba-like objects for converting XDM::AtomicValues into
    # appropriate Ruby values
    module ValueToRuby
      module Patterns
        DATE_TIME = /\A(-?[0-9]{4,})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}(?:\.[0-9]+)?)(Z|[-+][0-9]{2}:[0-9]{2})?\z/
      end

      class DateTimeConvertor
        def self.call(xdm_atomic_value)
          new(xdm_atomic_value).convert
        end

        attr_reader :timestring, :match

        def initialize(xdm_atomic_value)
          @timestring = xdm_atomic_value.to_s
          @match = ValueToRuby::Patterns::DATE_TIME.match(@timestring)
        end

        def convert
          return timestring if match.nil?
          Time.new(*integer_parts, decimal_part, tz_part)
        end

        def integer_parts
          match[1..5].map { |n| Integer(n, 10) }
        end

        def decimal_part
          Float(match[6])
        end

        def tz_part
          tz_string = match[7]
          tz_string == 'Z' ? '+00:00' : tz_string
        end
      end

      module Convertors
        INTEGER = INT = SHORT = LONG = UNSIGNED_INT = UNSIGNED_SHORT = UNSIGNED_LONG = \
        POSITIVE_INTEGER = NON_POSITIVE_INTEGER = NEGATIVE_INTEGER = NON_NEGATIVE_INTEGER = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        DECIMAL = ->(xdm_atomic_value) {
          BigDecimal(xdm_atomic_value.to_s)
        }
        FLOAT = DOUBLE = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        DATE_TIME = DATE_TIME_STAMP = ValueToRuby::DateTimeConvertor
        BOOLEAN = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        NOTATION = QNAME = ->(xdm_atomic_value) {
          Saxon::QName.new(xdm_atomic_value.to_java.getQNameValue)
        }
        BASE64_BINARY = ->(xdm_atomic_value) {
          Base64.decode64(xdm_atomic_value.to_s)
        }
        HEX_BINARY = ->(xdm_atomic_value) {
          bytes = []
          xdm_atomic_value.to_s.scan(/../) { |x| bytes << x.hex.chr(Encoding::ASCII_8BIT) }
          bytes.join
        }
        BYTE = ->(xdm_atomic_value) {
          [xdm_atomic_value.to_java.getLongValue].pack('c')
        }
        UNSIGNED_BYTE = ->(xdm_atomic_value) {
          [xdm_atomic_value.to_java.getLongValue].pack('C')
        }
      end
    end
  end
end
