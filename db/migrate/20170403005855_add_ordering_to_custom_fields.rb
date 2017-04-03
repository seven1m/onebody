class AddOrderingToCustomFields < ActiveRecord::Migration
  def change
    add_column :custom_fields, :ordering, :integer
  end
end
