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

      # @api private
      def initialize(s9_xdm_map)
        @s9_xdm_map = s9_xdm_map
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        to_h == other.to_h
      end

      def [](key)
        XDM.Value(@s9_xdm_map.get(XDM.AtomicValue(key).to_java))
      end

      def each(&block)
        @s9_xdm_map.entrySet.map { |entry| [XDM.AtomicValue(entry.getKey), XDM.Value(entry.getValue)] }.each(&block)
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
    end
  end
end
