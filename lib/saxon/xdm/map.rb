require_relative '../s9api'
require_relative 'sequence_like'

module Saxon
  module XDM
    # Represents an XDM Map
    class Map
      # Create an {XDM::Map} from a Ruby Hash, by ensuring each key has been
      # converted to an {AtomicValue}, and each value has been converted to an
      # XDM Value of some sort.
      # @return [XDM::Map] the new Map
      # @see XDM.AtomicValue
      # @see XDM.Value
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

      # Compare this Map against another. They're equal if they contain the same
      # key, value pairs.
      def ==(other)
        return false unless other.is_a?(self.class)
        to_h == other.to_h
      end

      # Fetch the value for the key given. +key+ is converted to an
      # {XDM::AtomicValue} if it isn't already one.
      # @param key [Object, XDM::AtomicValue] the key to retrieve
      def [](key)
        cached_hash[XDM.AtomicValue(key)]
      end

      # Fetch the value for the key given, as {Hash#fetch} would. +key+ is
      # converted to an {XDM::AtomicValue} if it isn't already one.
      # @param key [XDM::AtomicValue, Object] the key to retrieve.
      # @see Hash#fetch
      def fetch(key, *args, &block)
        cached_hash.fetch(XDM.AtomicValue(key), *args, &block)
      end

      # Iterate over the Map as {Hash#each} would
      # @yieldparam key [XDM::AtomicValue] the key
      # @yieldparam value [XDM::Value] the value
      def each(&block)
        cached_hash.each(&block)
      end

      # Return a new Map containing only key, value pairs for which the block
      # returns true.
      # @yieldparam key [XDM::AtomicValue] the key
      # @yieldparam value [XDM::Value] the value
      # @see ::Hash#select
      def select(&block)
        self.class.create(each.select(&block).to_h)
      end

      # Return a new Map containing only key, value pairs for which the block
      # DOES NOT return true.
      # @yieldparam key [XDM::AtomicValue] the key
      # @yieldparam value [XDM::Value] the value
      # @see ::Hash#reject
      def reject(&block)
        self.class.create(each.reject(&block).to_h)
      end

      # Create a new Map from the result of merging another Map into this one.
      # In the case of duplicate keys, the value in the provided hash will be
      # used.
      # @yieldparam key [XDM::AtomicValue] the key
      # @yieldparam value [XDM::Value] the value
      # @return [XDM::Map] the new Map
      # @see ::Hash#merge
      def merge(other)
        self.class.create(to_h.merge(other.to_h))
      end

      # @return [S9API::XdmMap] the underlying Saxon XdmMap
      def to_java
        @s9_xdm_map
      end

      # a (frozen) Ruby hash containing the keys and values from the Map.
      # @return [Hash] the Map as a Ruby hash.
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
