class AddAutoAddToGroups < ActiveRecord::Migration
  def change
    change_table :groups do |t|
      t.string :auto_add, limit: 10
    end
  end
end
