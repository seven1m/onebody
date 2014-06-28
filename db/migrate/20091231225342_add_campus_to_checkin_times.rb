class AddCampusToCheckinTimes < ActiveRecord::Migration
  def self.up
    change_table :checkin_times do |t|
      t.string :campus
    end
  end

  def self.down
    change_table :checkin_times do |t|
      t.remove :campus
    end
  end
end
