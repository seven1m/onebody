class CreateGroupTimes < ActiveRecord::Migration
  def self.up
    create_table :group_times do |t|
      t.integer :group_id
      t.integer :checkin_time_id
      t.integer :ordering
      t.integer :site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :group_times
  end
end
