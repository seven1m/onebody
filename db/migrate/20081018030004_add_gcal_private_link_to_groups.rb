class AddGcalPrivateLinkToGroups < ActiveRecord::Migration
  def self.up
    change_table :groups do |t|
      t.string :gcal_private_link, :limit => 255
    end
  end

  def self.down
    change_table :groups do |t|
      t.remove :gcal_private_link
    end
  end
end
