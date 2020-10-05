require 'pathname'
require 'java'

module Saxon
  # A sensible namespace to put Saxon Java classes into
  module S9API
  end

  # The mechanism for adding the JARs for either the bundled Saxon HE, or an
  # external Saxon HE/PE/EE version, into the CLASSPATH and requiring them.
  module Loader
    LOAD_SEMAPHORE = Mutex.new
    private_constant :LOAD_SEMAPHORE

    # Error raised if Saxon::Loader.load! is called but the path handed
    # in does not exist or is not a directory
    class NoJarsError < StandardError
      def initialize(path)
        @path = path
      end

      # returns an error message including the missing path
      def to_s
        "The path ('#{@path}') you supplied for the Saxon .jar files doesn't exist, sorry"
      end
    end

    # Error raised if Saxon::Loader.load! is called but the path handed
    # in does not contain the Saxon .jars
    class MissingJarError < StandardError
      def initialize(path)
        @path = path
      end

      # returns an error message including the path looked in and jars we were looking for
      def to_s
        "One of saxon9he.jar, saxon9pe.jar, or saxon9ee.jar must be present in the path ('#{@path}') you supplied, sorry"
      end
    end

    class << self
      # Are the Saxon jars missing from the Classpath?
      # @return [Boolean] true if the Jars are not on the Classpath
      def jars_not_on_classpath?
        begin
          Java::net.sf.saxon.s9api.Processor
          false
        rescue
          true
        end
      end

      # Are the Saxon JARs on the Classpath?
      # @return [Boolean] whether the Jars are on the Classpath already
      def jars_on_classpath?
        !jars_not_on_classpath?
      end

      # @param saxon_home [String, Pathname] the path to the dir containing
      #   Saxon's .jars. Defaults to the vendored Saxon HE
      # @return [true, false] Returns true if Saxon had not been loaded and
      #   is now, and false if Saxon was already loaded
      def load!(saxon_home = nil)
        return false if instance_variable_defined?(:@saxon_loaded) && @saxon_loaded
        LOAD_SEMAPHORE.synchronize do
          if Saxon::S9API.const_defined?(:Processor)
            false
          else
            if jars_not_on_classpath?
              if saxon_home.nil?
                require 'saxon-rb_jars'
              else
                saxon_home = Pathname.new(saxon_home)
                raise NoJarsError, saxon_home unless saxon_home.directory?
                jars = [main_jar(saxon_home)].compact
                raise MissingJarError if jars.empty?
                jars += extra_jars(saxon_home)

                add_jars_to_classpath!(saxon_home, jars)
              end
            end

            require_relative 'jruby_bug_6197_workaround'
            @saxon_loaded = true
            true
          end
        end
      end

      private

      def main_jar(path)
        path.children.find { |jar|
          !jar.basename.to_s.match(/^saxon(?:9[hpe]e\.jar|-[hpe]e-10\.[0-9]+\.jar)$/).nil?
        }
      end

      def extra_jars(path)
        optional = ['saxon9-unpack.jar', 'saxon9-sql.jar'].map { |jar| path.join(jar) }.select { |jar| jar.file? }
        icu = path.children.find { |jar| jar.extname == '.jar' && !jar.basename.to_s.match(/^saxon-icu|^icu4j/).nil? }
        ([icu] + optional).compact
      end

      def add_jars_to_classpath!(saxon_home, jars)
        jars.each do |jar|
          $CLASSPATH << jar.to_s
        end
      end
    end
  end
end
