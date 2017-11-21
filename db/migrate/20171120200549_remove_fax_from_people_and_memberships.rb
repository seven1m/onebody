class RemoveFaxFromPeopleAndMemberships < ActiveRecord::Migration[5.1]
  def up
    remove_column :people, :fax
    remove_column :people, :share_fax
    remove_column :memberships, :share_fax
  end
end
