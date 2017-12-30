class MeetingMembershipType < ApplicationRecord
  has_many :meeting_memberships, dependent: :destroy
  has_many :people, -> { order(:last_name, :first_name) }, through: :meeting_memberships
end
