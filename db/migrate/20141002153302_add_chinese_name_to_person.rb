class AddChineseNameToPerson < ActiveRecord::Migration
  def change
    add_column :people, :chinese_name, :string
  end
end
