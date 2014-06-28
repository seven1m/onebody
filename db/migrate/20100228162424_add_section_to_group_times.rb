class AddSectionToGroupTimes < ActiveRecord::Migration
  def self.up
    change_table :group_times do |t|
      t.string :section, :limit => 100
    end
  end

  def self.down
    change_table :group_times do |t|
      t.remove :section
    end
  end
end
