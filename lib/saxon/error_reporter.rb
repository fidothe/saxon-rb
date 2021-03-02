require_relative 'xml_processing_error'

module Saxon
  class ErrorReporter
    def self.setup
      Saxon::Loader.load!
      include Java::net.sf.saxon.lib.ErrorReporter
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
