require_relative '../sequence_type'

module Saxon
  module XPath
    # Represents an XPath variable declaration in the static context of a
    # compiled XPath, providing an idiomatic Ruby way to deal with these.
    class VariableDeclaration
      # @return [Saxon::QName]
      attr_reader :qname
      # @return [Saxon::SequenceType]
      attr_reader :sequence_type

      # @param qname [Saxon::QName] the name of the variable
      # @param sequence_type [Saxon::SequenceType] the SequenceType of the
      #   variable
      def initialize(qname, sequence_type)
        @qname = qname
        @sequence_type = sequence_type || Saxon.SequenceType('item()*')
      end

      # VariableDeclarations compare equal if their qname and sequence_type are equal
      # @param other [Saxon::VariableDeclaration]
      # @return [Boolean]
      def ==(other)
        VariableDeclaration === other && qname == other.qname && sequence_type == other.sequence_type
      end

      # @api private
      # return the arguments XPathCompiler.declareVariable expects
      def compiler_args
        [qname.to_java, sequence_type.item_type.to_java, sequence_type.occurrence_indicator.to_java]
      end
    end
  end
end
