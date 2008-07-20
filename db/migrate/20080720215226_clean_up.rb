class CleanUp < ActiveRecord::Migration
  def self.up
    remove_column :families, :security_token
  end

  def self.down
    add_column :families, :security_token, :string, :limit => 25
  end
end
