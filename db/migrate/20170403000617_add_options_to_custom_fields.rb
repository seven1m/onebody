class AddOptionsToCustomFields < ActiveRecord::Migration
  def change
    add_column :custom_fields, :options, :text
  end
end
