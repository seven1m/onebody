class AddRequiredToCustomFields < ActiveRecord::Migration
  def change
    add_column :custom_fields, :required, :boolean, default: false
  end
end
