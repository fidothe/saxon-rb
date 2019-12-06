require 'saxon/loader'

module Saxon
  module S9API
    CLASS_IMPORT_SEMAPHORE = Mutex.new
    private_constant :CLASS_IMPORT_SEMAPHORE

    class << self
      # Override the +const_missing+ hook in {S9API} so that we can delay
      # loading the Saxon JARs until the user has had a chance to set an
      # alternate location for them, if they don't want to use the bundled Saxon
      # HE
      def const_missing(name)
        Saxon::Loader.load!
        begin
          const_set(name, imported_classes.const_get(name))
        rescue NameError
          msg = "uninitialized constant Saxon::S9API::#{name}"
          e = NameError.new(msg, name)
          raise e
        end
      end

      private

      def imported_classes
        return @imported_classes if instance_variable_defined?(:@imported_classes)
        CLASS_IMPORT_SEMAPHORE.synchronize do
          @imported_classes = Module.new {
            include_package 'net.sf.saxon.s9api'
            java_import Java::net.sf.saxon.Configuration
            java_import Java::net.sf.saxon.lib.FeatureKeys
            java_import Java::net.sf.saxon.lib.ParseOptions
          }
        end
      end
    end
  end
end
