require 'active_support/concern'

module Concerns
  module Person
    module MeetingMemberships
      extend ActiveSupport::Concern

      included do
        has_many :meeting_memberships, dependent: :destroy
        has_many :meetings, through: :meeting_memberships
        after_destroy :destroy_meeting_memberships
      end

      def has_meeting?(meeting)
        meeting_memberships.where(meeting_id: meeting.id).any?
      end

      def has_any_meeting?()
        meeting_memberships.all().any?
      end

      def destroy_meeting_memberships
        meeting_memberships.destroy_all
      end
    end
  end
end
