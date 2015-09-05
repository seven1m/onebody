class AddIndexOnPeopleEmail < ActiveRecord::Migration
  def change
    add_index :people, :email
  end
end
