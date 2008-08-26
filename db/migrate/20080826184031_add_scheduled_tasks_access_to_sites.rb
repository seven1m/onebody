class AddScheduledTasksAccessToSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      t.boolean :edit_tasks_enabled, :default => true
    end
  end

  def self.down
    change_table :sites do |t|
      t.remove :edit_tasks_enabled
    end
  end
end
