require_relative '../item_type'
require_relative '../occurrence_indicator'

module Saxon
  module XPath
    # Represents an XPath variable declaration in the static context of a compiled XPath, providing an idiomatic Ruby way to deal with these.
    class VariableDeclaration
      # @return [Saxon::QName]
      attr_reader :qname
      # @return [Saxon::ItemType]
      attr_reader :item_type
      # @return [net.sf.saxon.s9api.OccurrenceIndicator]
      attr_reader :occurrences

      # @param opts [Hash]
      # @option opts [Saxon::QName] :qname The name of the variable as a {Saxon::QName}
      def initialize(opts = {})
        raise VariableDeclarationError, opts.keys if opts.keys.length > 2
        @qname = opts.fetch(:qname)
        @item_type, @occurrences = extract_type_decl(opts.reject { |k, v| k == :qname })
      end

      # VariableDeclarations compare equal if their qname, item_type, and occurrences are equal
      # @param other [Saxon::VariableDeclaration]
      # @return [Boolean]
      def ==(other)
        VariableDeclaration === other && qname == other.qname && item_type == other.item_type && occurrences == other.occurrences
      end

      # @api private
      def compiler_args
        [qname.to_java, item_type.to_java, occurrences]
      end

      private

      def self.valid_opt_keys
        @valid_opt_keys ||= [:qname] + Saxon::OccurrenceIndicator.indicator_names
      end

      def extract_type_decl(type_decl)
        raise VariableDeclarationError, type_decl.keys if type_decl.length > 1
        unless (type_decl.keys - Saxon::OccurrenceIndicator.indicator_names).empty?
          raise VariableDeclarationError, type_decl.keys
        end

        return [Saxon::ItemType.get_type('item()'), Saxon::OccurrenceIndicator.zero_or_more] if type_decl.empty?
        occurrence, type = type_decl.first
        [Saxon::ItemType.get_type(type), Saxon::OccurrenceIndicator.send(occurrence)]
      end
    end

    # Raised when an attempt to declare a variable is made using an occurrence
    # indicator that does not exist
    class VariableDeclarationError < StandardError
      attr_reader :keys

      def initialize(keys)
        @keys = keys
      end

      # reports allowable occurrence indicator keys and what was actually passed in
      def to_s
        "requires :qname, and optionally one of #{Saxon::OccurrenceIndicator.indicator_names}, was passed #{keys.join(', ')}"
      end
    end
  end
end
