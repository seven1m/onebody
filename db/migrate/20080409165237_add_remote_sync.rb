class AddRemoteSync < ActiveRecord::Migration
  def self.up
    create_table :sync_instances do |t|
      t.integer :site_id
      t.integer :owner_id
      t.integer :person_id
      t.integer :remote_id
      t.integer :remote_account_id
      t.string :account_type, :limit => 25 # highrise, plaid, etc.
      t.timestamps # updated_at will serve as last_sync timestamp
    end
    
    create_table :remote_accounts do |t|
      t.integer :site_id
      t.integer :person_id
      t.string :account_type, :limit => 25 # highrise, plaid, etc.
      t.string :username, :limit => 255
      t.string :token, :limit => 500
    end
  end

  def self.down
    drop_table :sync_instances
    drop_table :remote_accounts
  end
end
