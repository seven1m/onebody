class AddIndexOnPeopleEmail < ActiveRecord::Migration[4.2]
  def change
    add_index :people, :email
  end
end
