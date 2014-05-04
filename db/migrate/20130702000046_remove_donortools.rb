class RemoveDonortools < ActiveRecord::Migration
  def up
    change_table :people do |t|
      t.remove :donortools_id
      t.remove :synced_to_donortools
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
