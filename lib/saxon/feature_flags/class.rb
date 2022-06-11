module Saxon
  module FeatureFlags
    module Class
      CLASS_CHECKER_SEMAPHORE = Mutex.new

      # Wrap the class so that it will only be usable if the version constraint
      # is satisfied, and explode otherwise.
      #
      # We can't know what version of Saxon is in use at code load time, only
      # once {Saxon::Loader#load!} has been called, either explicitly or by
      # calling a method which requires a Saxon Java object. Therefore, we have
      # to check this the first time someone tries to use the class.
      #
      # Creating this check wraps the target class with one that checks the
      # version, and runs the original version if its constraint is satisfied.
      #
      # To avoid performing the check every time the class is accessed, once we
      # know whether or not the constraint is satisfied, we assume that the
      # verion of Saxon cannot be unloaded and a new one loaded in its place and
      # unwrap the class so the original is left (if the constraint is passed),
      # or replace it with one that simply +raise+s the constraint error if
      # instantiation or class method calls are attempted.
      #
      # @param klass [Class] the class to wrap
      # @param version_constraint [String] the version constraint
      #   (<tt>'>9.9.1.7'</tt> or <tt>'>= 9.9'</tt>)
      def self.critical(klass, version_constraint)
        CLASS_CHECKER_SEMAPHORE.synchronize do
          FeatureFlags::Method.critical(klass, :initialize, version_constraint)
          klass.methods(false).each do |method_name|
            FeatureFlags::Method.critical(klass.singleton_class, method_name, version_constraint)
          end
        end
      end
    end
  end
end
