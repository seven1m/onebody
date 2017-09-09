class AddFieldsToSupportOmniAuth < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :provider, :string
    add_column :people, :uid, :string
  end
end
