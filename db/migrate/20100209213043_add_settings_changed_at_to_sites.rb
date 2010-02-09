class AddSettingsChangedAtToSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      t.datetime :settings_changed_at
    end
  end

  def self.down
    change_table :sites do |t|
      t.remove :settings_changed_at
    end
  end
end
