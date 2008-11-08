class ChangeLimitOnState < ActiveRecord::Migration
  def self.up
    change_column :families, :state, :string, :limit => 10
  end

  def self.down
    change_column :families, :state, :string, :limit => 2
  end
end
