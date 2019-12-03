require_relative './item_type'
require_relative './occurrence_indicator'

module Saxon
  class SequenceType
    # Generate a {SequenceType} from a declaration string following the rules of
    # parameter and function declarations in XSLT, like <tt>xs:string+</tt>
    #
    # @param type_decl [String] the declaration string
    # @return [Saxon::SequenceType] the resulting SequenceType
    def self.from_type_decl(type_decl)
      occurence_char = type_decl[-1]
      occurence = case occurence_char
      when '?'
        new(ItemType.get_type(type_decl[0..-2]), OccurrenceIndicator.zero_or_one)
      when '+'
        new(ItemType.get_type(type_decl[0..-2]), OccurrenceIndicator.one_or_more)
      when '*'
        new(ItemType.get_type(type_decl[0..-2]), OccurrenceIndicator.zero_or_more)
      else
        new(ItemType.get_type(type_decl), OccurrenceIndicator.one)
      end
    end

    # @overload initialize(item_type, occurrence_indicator)
    #   creates new instance using item type and occurrence indicator
    #   @param item_type [Saxon::ItemType] the sequence's item type
    #   @param occurrence_indicator [net.sf.saxon.s9api.OccurrenceIndicator] the
    #     occurrence indicator (cardinality) of the sequence
    # @overload initialize(s9_sequence_type)
    #   create a new instance by wrapping one of Saxon's underlying Java
    #   +SequenceType+s
    #   @param s9_sequence_type [net.sf.saxon.s9api.SequenceType]
    # @return [Saxon::SequenceType] the new SequenceType
    def initialize(item_type, occurrence_indicator = nil)
      if occurrence_indicator.nil? && !item_type.is_a?(S9API::SequenceType)
        raise ArgumentError, "Expected a Java s9api.SequenceType when handed a single argument, but got a #{item_type.class}"
      end

      if occurrence_indicator.nil?
        @s9_sequence_type = item_type
      else
        @item_type = item_type
        @occurrence_indicator = occurrence_indicator
      end
    end

    # @return [Saxon::ItemType] the type's ItemType
    def item_type
      @item_type ||= Saxon::ItemType.get_type(s9_sequence_type.getItemType)
    end

    # @return [net.sf.saxon.s9api.OccurrenceIndicator] the type's OccurrenceIndicator
    def occurrence_indicator
      @occurrence_indicator ||= s9_sequence_type.getOccurrenceIndicator
    end

    # @return [net.sf.saxon.s9api.SequenceType] the underlying Saxon SequenceType
    def to_java
      s9_sequence_type
    end

    # Compare equal with another SequenceType
    # @param other [Saxon::SequenceType]
    # @return [Boolean] the result of comparing +self+ and +other+
    def ==(other)
      return false if other.class != self.class
      item_type == other.item_type && occurrence_indicator == other.occurrence_indicator
    end
    alias_method :eql?, :==

    # Generated hash code for use as keys in Hashes
    def hash
      @hash ||= item_type.hash ^ occurrence_indicator.hash
    end

    private

    def s9_sequence_type
      @s9_sequence_type ||= S9API::SequenceType.makeSequenceType(item_type.to_java, occurrence_indicator.to_java)
    end
  end
end