class RemoveScheduledTasks < ActiveRecord::Migration
  def self.up
    drop_table :scheduled_tasks
    change_table :sites do |t|
      t.remove :edit_tasks_enabled
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert this migration.'
  end
end
