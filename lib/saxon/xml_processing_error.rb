require_relative 'qname'

module Saxon
  class XMLProcessingError
    attr_reader :s9_error
    private :s9_error

    def initialize(s9_error)
      @s9_error = s9_error
    end

    def message
      s9_error.getMessage
    end

    def error_code
      @error_code ||= Saxon::QName.new(s9_error.getErrorCode)
    end

    def warning?
      s9_error.isWarning
    end

    def fatal?
      !s9_error.getFatalErrorMessage.nil?
    end

    def static_error?
      s9_error.isStaticError
    end

    def type_error?
      s9_error.isTypeError
    end

    def to_java
      s9_error
    end
  end
end
