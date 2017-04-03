class AddKindToCustomFields < ActiveRecord::Migration
  def up
    add_column :custom_fields, :kind, :string
    add_index :custom_fields, :kind

    CustomField.reset_column_information

    Site.each do
      CustomField.find_each do |custom_field|
        custom_field.kind = 'person'
        custom_field.save(validate: false)
      end
    end
  end

  def down
    remove_column :custom_fields, :kind, :string
  end
end
