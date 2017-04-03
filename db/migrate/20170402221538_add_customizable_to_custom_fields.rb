class AddCustomizableToCustomFields < ActiveRecord::Migration
  def change
    add_column :custom_fields, :customizable_type, :string, index: true
    add_column :custom_fields, :customizable_id, :integer, index: true
  end
end
