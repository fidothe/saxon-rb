require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents an XDM Map
    class Map
      def self.create(hash)
        case hash
        when Saxon::S9API::XdmMap
          new(hash)
        else
          new(S9API::XdmMap.new(Hash[
            hash.map { |key, value|
              [XDM.AtomicValue(key).to_java, XDM.Value(value).to_java]
            }
          ]))
        end
      end

      include SequenceLike
      include ItemSequenceLike
      include Enumerable

      attr_reader :s9_xdm_map
      private :s9_xdm_map

      # @api private
      def initialize(s9_xdm_map)
        @s9_xdm_map = s9_xdm_map
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        to_h == other.to_h
      end

      def [](key)
        cached_hash[XDM.AtomicValue(key)]
      end

      def fetch(key, *args, &block)
        cached_hash.fetch(XDM.AtomicValue(key), *args, &block)
      end

      def each(&block)
        cached_hash.each(&block)
      end

      def select(&block)
        self.class.create(each.select(&block).to_h)
      end

      def reject(&block)
        self.class.create(each.reject(&block).to_h)
      end

      def merge(other)
        self.class.create(to_h.merge(other.to_h))
      end

      def to_java
        @s9_xdm_map
      end

      def to_h
        cached_hash
      end

      private

      def cached_hash
        @cached_hash ||= s9_xdm_map.entrySet.map { |entry| [XDM.AtomicValue(entry.getKey), XDM.Value(entry.getValue)] }.to_h.freeze
      end
    end
  end
end
