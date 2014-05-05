class RemovePublications < ActiveRecord::Migration
  def up
    drop_table :publications
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
