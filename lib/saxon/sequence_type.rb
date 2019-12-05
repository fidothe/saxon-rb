require_relative './item_type'
require_relative './occurrence_indicator'

module Saxon
  # Represents a type definition for an XDM Sequence: an {ItemType} plus an
  # {OccurrenceIndicator} as a restriction on the cardinality (length) of the
  # sequence. Used most often to define variables in XPath or XSLT, plus in
  # extension function definition.
  class SequenceType
    class << self
      # Generate a {SequenceType} from a type declaration string (see
      # {.from_type_decl}), or some combination of type name/Ruby class (see
      # {ItemType.get_type}), and an {OccurrenceIndicator} or symbol referencing
      # an OccurenceIndicator (one of +:zero_or_more+, +:one_or_more+,
      # +:zero_or_one+, or +:one+)
      #
      # @return [Saxon::SequenceType] the resulting SequenceType
      def create(type_name, occurrence_indicator = nil)
        case type_name
        when SequenceType
          return type_name
        when S9API::SequenceType
          return new(type_name)
        else
          check_for_complete_decl!(type_name, occurrence_indicator)
          return from_type_decl(type_name) if type_name.is_a?(String) && occurrence_indicator.nil?
          item_type = ItemType.get_type(type_name)
          occurrence_indicator = OccurrenceIndicator.get_indicator(occurrence_indicator)
          new(item_type, occurrence_indicator)
        end
      end

      # Generate a {SequenceType} from a declaration string following the rules
      # of parameter and function +as=+ declarations in XSLT, like
      # <tt><xsl:variable ... as="xs:string+"/></tt>
      #
      # @param type_decl [String] the declaration string
      # @return [Saxon::SequenceType] the resulting SequenceType
      def from_type_decl(type_decl)
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

      private

      def check_for_complete_decl!(type_name, occurrence_indicator)
        return true if occurrence_indicator.nil?
        if type_name_is_complete_decl?(type_name)
          raise ArgumentError, "Cannot pass a complete type declaration (#{type_name}) and an OccurrenceIndicator"
        end
      end

      def type_name_is_complete_decl?(type_name)
        !!(type_name.is_a?(String) && type_name.match(/[+*?]$/))
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

  # Convenience wrapper for {SequenceType.create}
  # @see SequenceType.create
  def self.SequenceType(*args)
    SequenceType.create(*args)
  end
end
