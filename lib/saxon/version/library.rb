require 'saxon/s9api'

module Saxon
  module Version
    # The version of the underlying Saxon library, which we need to discover at
    # runtime based on what version is on the Classpath
    class Library
      def self.loaded_version
        Saxon::Loader.load!

        sv = Java::net.sf.saxon.Version
        new(sv.getProductVersion, sv.getStructuredVersionNumber, sv.softwareEdition)
      end

      include Comparable

      # @return [String] the version string (e.g. '9.9.1.6', '10.0')
      attr_reader :version
      # @return [String] the version components (e.g. <tt>[9, 9, 1, 6]</tt>, <tt>[10, 0]</tt>)
      attr_reader :components
      # @return [Symbol] the edition (+:he+, +:pe+, or +:ee+)
      attr_reader :edition

      def initialize(version, components, edition)
        @version = version.dup.freeze
        @components = components.dup.freeze
        @edition = edition.downcase.to_sym
      end

      def <=>(other)
        return false unless other.is_a?(self.class)

        n_components = [self.components.length, other.components.length].max
        (0..(n_components - 1)).reduce(0, &comparator(other))
      end

      def pessimistic_compare(pessimistic_version)
        pessimistic_components = pessimistic_version.components
        pessimistic_components = pessimistic_components + [0] if pessimistic_components.length == 1
        locked = pessimistic_components[0..-2]
        locked = locked.zip(components[0..locked.length])
        variable = [pessimistic_components[-1], components[locked.length]]

        locked_ok = locked.all? { |check, mine|
          check == mine
        }

        return false unless locked_ok

        check, mine = variable
        mine >= check
      end

      def to_s
        version
      end

      private

      def comparator(other)
        ->(cmp, i) {
          return cmp unless cmp == 0

          mine = self.components[i].nil? ? 0 : self.components[i]
          theirs = other.components[i].nil? ? 0 : other.components[i]

          mine <=> theirs
        }
      end
    end
  end
end