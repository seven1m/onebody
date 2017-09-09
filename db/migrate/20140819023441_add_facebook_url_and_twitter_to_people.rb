class AddFacebookUrlAndTwitterToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :facebook_url, :string
    add_column :people, :twitter, :string, limit: 15
  end
end
