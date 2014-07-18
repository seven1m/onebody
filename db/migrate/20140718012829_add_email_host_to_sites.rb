class AddEmailHostToSites < ActiveRecord::Migration
  def change
    change_table :sites do |t|
      t.string :email_host
    end
  end
end
