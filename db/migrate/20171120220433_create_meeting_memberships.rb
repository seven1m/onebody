class CreateMeetingMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :meeting_memberships do |t|
      t.integer :person_id, foreign_key: true
      t.integer :meeting_id, foreign_key: true
      t.date :member_since

      t.timestamps
    end
  end
end
