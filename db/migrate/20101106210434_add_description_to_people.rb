class AddDescriptionToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :description, :limit => 25
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :description
    end
  end
end
