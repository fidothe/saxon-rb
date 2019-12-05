require_relative 's9api'

module Saxon
  # Provides simple access to Saxon's OccurrenceIndicator constants, for
  # declaring restrictions on the cardinality (length) of a sequence when, for
  # example, defining a variable's type
  module OccurrenceIndicator
    class << self
      # One thing
      def one
        @one ||= Saxon::S9API::OccurrenceIndicator::ONE
      end

      # One or more things
      def one_or_more
        @one_or_more ||= Saxon::S9API::OccurrenceIndicator::ONE_OR_MORE
      end

      # no things (the empty sequence)
      def zero
        @zero ||= Saxon::S9API::OccurrenceIndicator::ZERO
      end

      # zero or more things
      def zero_or_more
        @zero_or_more ||= Saxon::S9API::OccurrenceIndicator::ZERO_OR_MORE
      end

      # an optional thing
      def zero_or_one
        @zero_or_one ||= Saxon::S9API::OccurrenceIndicator::ZERO_OR_ONE
      end

      # The list of valid occurence indicator names, as symbols. These
      # correspond directly to the methods returning OccurrenceIndicators in
      # this module.
      #
      # @return [Array<Symbol>] the indicator names
      def indicator_names
        # .refine gets added to modules that have methods, so it's not in
        # Module's public_methods list
        @indicator_names ||= (public_methods(false) - Module.public_methods - [:indicator_names, :get_indicator, :refine])
      end

      # Return an OccurrenceIndicator given a name as a symbol. Passes through
      # existing OccurrenceIndicator instances: this method is primarily for API
      # use, most people will find it easier to directly call one of the
      # methods, as in +OccurrenceIndicator.one+ rather than
      # +OccurrenceIndicator.get_indicator(:one)+.
      #
      # @param indicator_name [Symbol, Saxon::S9API::OccurrenceIndicator] the name of the OccurrenceIndicator to return
      # @return [Saxon::S9API::OccurrenceIndicator] the OccurrenceIndicator
      def get_indicator(indicator_name)
        return indicator_name if indicator_name.is_a?(Saxon::S9API::OccurrenceIndicator)
        unless indicator_names.include?(indicator_name)
          raise ArgumentError, "#{indicator_name.inspect} is not a valid indicator name (one of #{indicator_names.map(&:inspect).join(', ')})"
        end
        OccurrenceIndicator.send(indicator_name)
      end
    end
  end
end
