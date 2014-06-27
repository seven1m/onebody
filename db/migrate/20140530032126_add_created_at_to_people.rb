class AddCreatedAtToPeople < ActiveRecord::Migration
  def change
    change_table :people do |t|
      t.datetime "created_at"
    end
  end
end
