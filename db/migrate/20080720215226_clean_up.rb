class CleanUp < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.remove :security_token
      t.remove :email
      t.remove :mail_group
    end
  end

  def self.down
    change_table :families do |t|
      t.string :security_token, :limit => 25
      t.string :email
      t.string :mail_group, :limit => 1
    end
  end
end
