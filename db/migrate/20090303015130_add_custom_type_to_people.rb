class AddCustomTypeToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :custom_type, :limit => 100
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :custom_type
    end
  end
end
