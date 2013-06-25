class RemoveLogItems < ActiveRecord::Migration
  def up
    drop_table(:log_items)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
