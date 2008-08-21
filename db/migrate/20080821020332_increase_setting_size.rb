class IncreaseSettingSize < ActiveRecord::Migration
  def self.up
    change_column :settings, :value, :string, :limit => 500
  end

  def self.down
  end
end
