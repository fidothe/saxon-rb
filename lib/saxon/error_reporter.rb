require_relative 'xml_processing_error'

module Saxon
  class ErrorReporter
    def self.setup
      Saxon::Loader.load!
      include Java::net.sf.saxon.lib.ErrorReporter
    end

    def self.create(reporter_or_callable)
      case reporter_or_callable
      when self
        reporter_or_callable
      else
        new(reporter_or_callable)
      end
    end

    attr_reader :callable

    def initialize(callable)
      self.class.setup
      @callable = callable
    end

    def report(xml_processing_error)
      callable.call(Saxon::XMLProcessingError.new(xml_processing_error))
    end
  end
end
