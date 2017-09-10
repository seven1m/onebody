class AddPositionToCustomFields < ActiveRecord::Migration[4.2]
  def up
    add_column :custom_fields, :position, :integer

    CustomField.reset_column_information
    Site.each do
      CustomField.order(:id).each_with_index do |field, index|
        field.position = index + 1
        field.save!
      end
    end
  end

  def down
    remove_column :custom_fields, :position, :integer
  end
end
