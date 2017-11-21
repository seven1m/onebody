class AddSecondNameAndThirdNameToPerson < ActiveRecord::Migration[5.1]
  def up
    add_column :people, :second_name, :text
    add_column :people, :third_name, :text
  end
end
