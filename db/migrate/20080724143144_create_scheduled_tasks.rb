class CreateScheduledTasks < ActiveRecord::Migration
  def self.up
    create_table :scheduled_tasks do |t|
      t.string :name, :limit => 100
      t.text :command
      t.string :interval
      t.boolean :active, :default => true
      t.boolean :runner, :default => true
      t.integer :site_id
      t.timestamps
    end
    Site.each { |s| s.add_tasks }
    Setting.update_all
  end

  def self.down
    drop_table :scheduled_tasks
  end
end
