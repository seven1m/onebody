class RemoveWall < ActiveRecord::Migration
  def up
    change_table :families do |t|
      t.remove :wall_enabled
    end
    change_table :messages do |t|
      t.remove :wall_id
    end
    change_table :people do |t|
      t.remove :get_wall_email
      t.remove :wall_enabled
    end
    change_table :stream_items do |t|
      t.remove :wall_id
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
