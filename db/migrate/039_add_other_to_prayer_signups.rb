class AddOtherToPrayerSignups < ActiveRecord::Migration
  def self.up
    add_column :prayer_signups, :other, :string, :limit => 100
  end

  def self.down
    remove_column :prayer_signups, :other
  end
end
