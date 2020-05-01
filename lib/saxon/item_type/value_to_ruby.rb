require 'bigdecimal'

module Saxon
  class ItemType
    # A collection of lamba-like objects for converting XDM::AtomicValues into
    # appropriate Ruby values
    module ValueToRuby
      # Regexp patterns to assist in converting XDM typed values into Ruby
      # native types
      module Patterns
        # @see https://www.w3.org/TR/xmlschema-2/#dateTime-lexical-representation
        DATE_TIME = /\A(-?[0-9]{4,})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}(?:\.[0-9]+)?)(Z|[-+][0-9]{2}:[0-9]{2})?\z/
      end

      # Helper class that converts XDM Date/Time strings into something Ruby's {Time} class can
      # handle
      class DateTimeConvertor
        # Convert an XDM Date/Time value into a native Ruby {Time} object.
        # @return [Time, String] the converted Time, or the original XDM lexical
        #   string if conversion isn't possible
        def self.call(xdm_atomic_value)
          new(xdm_atomic_value).convert
        end

        attr_reader :timestring, :match

        def initialize(xdm_atomic_value)
          @timestring = xdm_atomic_value.to_s
          @match = ValueToRuby::Patterns::DATE_TIME.match(@timestring)
        end

        # Return a {Time} instance if possible, otherwise return the string value from the XDM.
        # @return [Time, String] the converted Time, or the original string
        def convert
          return timestring if match.nil?
          Time.new(*integer_parts, decimal_part, tz_part)
        end

        private

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

      # A collection of Lambdas (or objects responding to +#call+) for
      # converting XDM typed values to native Ruby types.
      module Convertors
        # @see https://www.w3.org/TR/xmlschema-2/#integer
        INTEGER = INT = SHORT = LONG = UNSIGNED_INT = UNSIGNED_SHORT = UNSIGNED_LONG = \
        POSITIVE_INTEGER = NON_POSITIVE_INTEGER = NEGATIVE_INTEGER = NON_NEGATIVE_INTEGER = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        # @see https://www.w3.org/TR/xmlschema-2/#decimal
        DECIMAL = ->(xdm_atomic_value) {
          BigDecimal(xdm_atomic_value.to_s)
        }
        # @see https://www.w3.org/TR/xmlschema-2/#float
        FLOAT = DOUBLE = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        # @see https://www.w3.org/TR/xmlschema-2/#dateTime
        DATE_TIME = DATE_TIME_STAMP = ValueToRuby::DateTimeConvertor
        # @see https://www.w3.org/TR/xmlschema-2/#boolean
        BOOLEAN = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
        # @see https://www.w3.org/TR/xmlschema-2/#NOTATION
        # @see https://www.w3.org/TR/xmlschema-2/#QName
        NOTATION = QNAME = ->(xdm_atomic_value) {
          Saxon::QName.new(xdm_atomic_value.to_java.getQNameValue)
        }
        # @see https://www.w3.org/TR/xmlschema-2/#base64Binary
        BASE64_BINARY = ->(xdm_atomic_value) {
          Base64.decode64(xdm_atomic_value.to_s)
        }
        # @see https://www.w3.org/TR/xmlschema-2/#hexBinary
        HEX_BINARY = ->(xdm_atomic_value) {
          bytes = []
          xdm_atomic_value.to_s.scan(/../) { |x| bytes << x.hex.chr(Encoding::ASCII_8BIT) }
          bytes.join
        }
        # @see https://www.w3.org/TR/xmlschema-2/#byte
        BYTE = ->(xdm_atomic_value) {
          [xdm_atomic_value.to_java.getLongValue].pack('c')
        }
        # @see https://www.w3.org/TR/xmlschema-2/#unsignedByte
        UNSIGNED_BYTE = ->(xdm_atomic_value) {
          [xdm_atomic_value.to_java.getLongValue].pack('C')
        }
      end
    end
  end
end
