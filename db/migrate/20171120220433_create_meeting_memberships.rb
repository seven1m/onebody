class CreateMeetingMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :meeting_memberships do |t|
      t.references :person, foreign_key: true
      t.references :meeting, foreign_key: true
      t.date :member_since

      t.timestamps
    end
  end
end
