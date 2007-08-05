class CreatePrayerRequests < ActiveRecord::Migration
  def self.up
    create_table :prayer_requests do |t|
      t.column :group_id, :integer
      t.column :person_id, :integer
      t.column :request, :text
      t.column :answer, :text
      t.column :answered_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :prayer_requests
  end
end
