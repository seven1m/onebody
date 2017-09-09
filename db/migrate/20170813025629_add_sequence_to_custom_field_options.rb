class AddSequenceToCustomFieldOptions < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_field_options, :sequence, :integer, default: 0
  end
end
