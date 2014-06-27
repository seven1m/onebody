class AddLatitudeAndLongitudeToGroups < ActiveRecord::Migration
  def change
    change_table :groups do |t|
      t.float :latitude, :longitude
    end
  end
end
