class UpdateSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      t.string :secondary_host, :limit => 255
      t.integer :max_admins, :max_people, :max_groups
      t.boolean :import_export_enabled, :pages_enabled, :pictures_enabled, :publications_enabled, :default => true
      t.boolean :active, :default => true
    end
  end

  def self.down
    change_table :sites do |t|
      t.remove :secondary_host
      t.remove :max_admins, :max_people, :max_groups
      t.remove :import_export_enabled, :pages_enabled, :pictures_enabled, :publications_enabled
      t.remove :active
    end
  end
end
