class AddMeetingMembershipTypeToMeetingMembership < ActiveRecord::Migration[5.1]
  def change
    add_column :meeting_memberships, :meeting_membership_type_id, :integer
  end
end
