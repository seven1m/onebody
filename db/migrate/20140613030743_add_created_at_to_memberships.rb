class AddCreatedAtToMemberships < ActiveRecord::Migration
  def change
    change_table :memberships do |t|
      t.datetime "created_at"
    end
  end
end
