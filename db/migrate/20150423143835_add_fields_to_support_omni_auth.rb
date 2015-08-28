class AddFieldsToSupportOmniAuth < ActiveRecord::Migration
  def change
    add_column :people, :provider, :string
    add_column :people, :uid, :string
  end
end
