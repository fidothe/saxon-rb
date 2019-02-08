require_relative 's9api'

module Saxon
  # Provides simple access to Saxon's OccurrenceIndicator constants,
  # for use in declaring variable types
  module OccurrenceIndicator
    class << self
      def one
        @one ||= Saxon::S9API::OccurrenceIndicator::ONE
      end

      def one_or_more
        @one_or_more ||= Saxon::S9API::OccurrenceIndicator::ONE_OR_MORE
      end

      def zero
        @zero ||= Saxon::S9API::OccurrenceIndicator::ZERO
      end

      def zero_or_more
        @zero_or_more ||= Saxon::S9API::OccurrenceIndicator::ZERO_OR_MORE
      end

      def zero_or_one
        @zero_or_one ||= Saxon::S9API::OccurrenceIndicator::ZERO_OR_ONE
      end

      def indicator_names
        @indicator_names ||= (public_methods(false) - Object.public_methods - [:indicator_names])
      end
    end
  end
end
