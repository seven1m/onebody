class AddSequenceToCustomFieldOptions < ActiveRecord::Migration
  def change
    add_column :custom_field_options, :sequence, :integer, default: 0
  end
end
