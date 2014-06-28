class CreateCheckinTimes < ActiveRecord::Migration
  def self.up
    create_table :checkin_times do |t|
      t.integer :weekday
      t.integer :time
      t.datetime :the_datetime # mutually exclusive with above attributes
      t.integer :site_id
      t.timestamps
    end
  end

  def self.down
    drop_table :checkin_times
  end
end
