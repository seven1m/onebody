class AddCmApiListIdToGroups < ActiveRecord::Migration
  def self.up
    change_table :groups do |t|
      t.string :cm_api_list_id, :limit => 50
    end
  end

  def self.down
    change_table :groups do |t|
      t.remove :cm_api_list_id
    end
  end
end
