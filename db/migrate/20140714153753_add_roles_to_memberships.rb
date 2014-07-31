class AddRolesToMemberships < ActiveRecord::Migration
  def change
    change_table :memberships do |t|
      t.text :roles
    end
  end
end
