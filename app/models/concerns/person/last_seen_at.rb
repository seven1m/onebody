require 'active_support/concern'

module Concerns
  module Person
    module LastSeenAt
      extend ActiveSupport::Concern

      LAST_SEEN_AT_INTERVAL = 1.hour # only update the last_seen_at column this often

      def update_last_seen_at
        return if last_seen_at && last_seen_at > LAST_SEEN_AT_INTERVAL.ago
        update_column(:last_seen_at, Time.current)
      end
    end
  end
end
