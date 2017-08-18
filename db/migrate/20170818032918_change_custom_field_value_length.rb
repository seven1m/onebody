class ChangeCustomFieldValueLength < ActiveRecord::Migration
  def up
    change_column :custom_field_values, :value, :text, limit: 65_535
  end

  def down
    change_column :custom_field_values, :value, :string
  end
end
