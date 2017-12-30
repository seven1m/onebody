class MeetingMembership < ApplicationRecord
  belongs_to :person
  belongs_to :meeting
  belongs_to :meeting_membership_type
end
