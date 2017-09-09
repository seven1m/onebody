class CreateCustomFieldTabs < ActiveRecord::Migration[4.2]
  def up
    create_table :custom_field_tabs do |t|
      t.integer :site_id, null: false
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps null: false
    end
    add_column :custom_fields, :tab_id, :integer

    CustomFieldTab.reset_column_information
    CustomField.reset_column_information

    Site.each do
      tab = CustomFieldTab.create!(
        name: 'Fields'
      )
      CustomField.update_all(tab_id: tab.id)
    end
  end

  def down
    drop_table :custom_field_tabs
    remove_column :custom_fields, :tab_id
  end
end
