class AddFamilyIdToUpdates < ActiveRecord::Migration
  def change
    change_table :updates do |t|
      t.integer :family_id
    end
  end
end
