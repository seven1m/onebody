class RemoveFeeds < ActiveRecord::Migration
  def up
    drop_table :feeds
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
