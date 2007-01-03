class CreatePrayerSignups < ActiveRecord::Migration
  def self.up
    create_table :prayer_signups do |t|
      t.column :person_id, :integer
      t.column :start, :datetime
      t.column :created_at, :datetime
      t.column :reminded, :boolean, :default => false
    end
  end

  def self.down
    drop_table :prayer_signups
  end
end
