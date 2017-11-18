class CreateRoleMembership < ActiveRecord::Migration[5.1]
  def change
    create_table :role_memberships do |t|
      t.integer "person_id"
      t.integer "role_id"
      t.integer "site_id"
    end
  end
end
