class CleanUp < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.remove :security_token rescue nil
      t.remove :mail_group
    end
  end

  def self.down
    change_table :families do |t|
      t.string :security_token, :limit => 25
      t.string :mail_group, :limit => 1
    end
  end
end
