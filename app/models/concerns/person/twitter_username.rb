require 'active_support/concern'

module Concerns
  module Person
    module TwitterUsername
      extend ActiveSupport::Concern

      included do
        validates :twitter,
                  length: { maximum: 15 },
                  format: { with: /\A[a-z0-9_]+\z/i },
                  allow_nil: true,
                  allow_blank: true

        before_validation :clean_twitter_username
      end

      def clean_twitter_username
        return unless twitter.present?
        self.twitter = twitter[1..-1] if twitter.start_with?('@')
      end
    end
  end
end
