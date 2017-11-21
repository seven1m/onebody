class RemoveRoleColumnsFromPeople < ActiveRecord::Migration[4.2]
  def up
    change_table :people do |t|
      t.remove :member, :staff, :elder, :deacon
    end
  end

  def down
    change_table :people do |t|
      t.boolean :member, :staff, :elder, :deacon
    end
  end
end