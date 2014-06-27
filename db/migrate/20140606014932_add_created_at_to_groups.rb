class AddCreatedAtToGroups < ActiveRecord::Migration
  def change
    change_table :groups do |t|
      t.datetime "created_at"
    end
  end
end
