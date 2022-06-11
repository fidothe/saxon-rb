module Saxon
  module FeatureFlags
    module Method
      CHECKER_SEMAPHORE = Mutex.new

      # Modify the method so that it will only run if the version constraint is
      # satisfied, and explode otherwise.
      #
      # We can't know what version of Saxon is in use at code load time, only
      # once {Saxon::Loader#load!} has been called, either explicitly or by
      # calling a method which requires a Saxon Java object. Therefore, we have
      # to check this the first time someone calls the method.
      #
      # Creating this check replaces the method on the target class with one
      # that checks the version, and runs the original version if its constraint
      # is satisfied.
      #
      # To avoid performing the check every time the method is called, once we
      # know whether or not the constraint is satisfied, we assume that the
      # verion of Saxon cannot be unloaded and a new one loaded in its place and
      # replace our version checking method with the original (if the constraint
      # is passed), or with one that simply +raise+s the constraint error.
      #
      # @param klass [Class] the class the method lives on
      # @param method_name [Symbol] the name of the method to be constrained
      # @param version_constraint [String] the version constraint
      #   (<tt>'>9.9.1.7'</tt> or <tt>'>= 9.9'</tt>)
      def self.critical(klass, method_name, version_constraint)
        version_constrained_methods_cache(klass).bind_method(method_name, version_constraint)
      end

      # Modify the method so that it will only run if the version constraint is
      # satisfied, and silently do nothing otherwise.
      #
      # @param klass [Class] the class the method lives on
      # @param method_name [Symbol] the name of the method to be constrained
      # @param version_constraint [String] the version constraint
      #   (<tt>'>9.9.1.7'</tt> or <tt>'>= 9.9'</tt>)
      def self.noop(klass, method_name, version_constraint)
        version_constrained_methods_cache(klass).bind_method_noop(method_name, version_constraint)
      end

      def self.version_constrained_methods_cache(klass)
        CHECKER_SEMAPHORE.synchronize {
          if klass.instance_variable_defined?(:@__version_constrained_methods_cache)
            klass.instance_variable_get(:@__version_constrained_methods_cache)
          else
            klass.instance_variable_set(:@__version_constrained_methods_cache, VersionConstrainedMethodsCache.new(klass))
          end
        }
      end

      class VersionConstrainedMethodsCache
        attr_reader :klass, :version_constraint_caches

        def initialize(klass)
          @klass = klass
          @version_constraint_caches = {}
        end

        def bind_method(method_name, version_constraint)
          get_cache(version_constraint).bind_method(method_name)
        end

        def bind_method_noop(method_name, version_constraint)
          get_cache(version_constraint).bind_method_noop(method_name)
        end

        def resolve!
          version_constraint_caches.each do |_, cache|
            cache.resolve!
          end
        end

        private

        def get_cache(version_constraint)
          CHECKER_SEMAPHORE.synchronize {
            version_constraint_caches[version_constraint] ||= new_constraint_cache(version_constraint)
          }
        end

        def new_constraint_cache(version_constraint)
          VersionContraintMethodCache.new(klass, FeatureFlags::Version.new(version_constraint), method(:resolve!))
        end
      end

      class VersionContraintMethodCache
        attr_reader :klass, :version_check, :explodey_methods, :noop_methods, :resolve_callback

        def initialize(klass, version_check, resolve_callback)
          @klass, @version_check, @resolve_callback = klass, version_check, resolve_callback
          @explodey_methods = {}
          @noop_methods = {}
          @resolved = false
        end

        def bind_method(method_name)
          CHECKER_SEMAPHORE.synchronize do
            return if method_already_bound?(method_name)
            explodey_methods[method_name] = klass.instance_method(method_name)

            klass.send(:define_method, method_name, wrapper_method_obj(method_name))
          end
        end

        def bind_method_noop(method_name)
          CHECKER_SEMAPHORE.synchronize do
            return if method_already_bound?(method_name)
            noop_methods[method_name] = klass.instance_method(method_name)

            klass.send(:define_method, method_name, noop_wrapper_method_obj(method_name))
          end
        end

        def resolve_call!(method_name, instance, args, kwargs, explode)
          resolve_callback.call
          if version_check_ok?
            call_through(method_name, instance, args, kwargs)
          else
            if explode
              raise UnavailableInThisSaxonVersionError
            else
              return nil
            end
          end
        end

        def resolve!
          if version_check_ok?
            rebind_all_methods!
          else
            make_all_methods_fail!
          end
        end

        private

        def version_check_ok?
          @version_check_ok ||= version_check.ok?
        end

        def exploding_method_obj
          ->(*args, **kwargs) {
            raise UnavailableInThisSaxonVersionError
          }
        end

        def noop_method_obj
          ->(*args, **kwargs) {
            nil
          }
        end

        def method_already_bound?(method_name)
          explodey_methods.has_key?(method_name) || noop_methods.has_key?(method_name)
        end

        def resolved?
          @resolved
        end

        def rebind_all_methods!
          CHECKER_SEMAPHORE.synchronize do
            return if resolved?
            explodey_methods.each do |method_name, method|
              klass.send(:define_method, method_name, method)
            end
            noop_methods.each do |method_name, method|
              klass.send(:define_method, method_name, method)
            end
            @resolved = true
          end
        end

        def make_all_methods_fail!
          CHECKER_SEMAPHORE.synchronize do
            return if resolved?
            explodey_methods.each do |method_name, _|
              klass.send(:define_method, method_name, exploding_method_obj)
            end
            noop_methods.each do |method_name, _|
              klass.send(:define_method, method_name, noop_method_obj)
            end
            @resolved = true
          end
        end

        def call_through(method_name, instance, args, kwargs)
          if args.empty? && kwargs.empty?
            get(method_name).bind(instance).call
          elsif args.empty?
            get(method_name).bind(instance).call(**kwargs)
          elsif kwargs.empty?
            get(method_name).bind(instance).call(*args)
          else
            get(method_name).bind(instance).call(*args, **kwargs)
          end
        end

        def get(method_name)
          explodey_methods[method_name] || noop_methods[method_name]
        end

        def wrapper_method_obj(method_name)
          cache = self
          ->(*args, **kwargs) {
            cache.resolve_call!(method_name, self, args, kwargs, true)
          }
        end

        def noop_wrapper_method_obj(method_name)
          cache = self
          ->(*args, **kwargs) {
            cache.resolve_call!(method_name, self, args, kwargs, false)
          }
        end
      end
    end
  end
end
