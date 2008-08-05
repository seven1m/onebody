class AddApiKeyToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :api_key, :limit => 50
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :api_key
    end
  end
end
