class AddCustomFieldsToPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.text :custom_fields
    end
    change_table :updates do |t|
      t.text :custom_fields
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :custom_fields
    end
    change_table :updates do |t|
      t.remove :custom_fields
    end
  end
end
