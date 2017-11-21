class AddMaritalStatusToPeople < ActiveRecord::Migration[5.1]
  def up
    add_column :people, :marital_status, :integer
  end
end
