class RemoveRemoteAccounts < ActiveRecord::Migration
  def self.up
    drop_table :remote_accounts
    drop_table :sync_instances
  end

  def self.down
    create_table "remote_accounts" do |t|
      t.integer "site_id"
      t.integer "person_id"
      t.string  "account_type", :limit => 25
      t.string  "username"
      t.string  "token", :limit => 500
    end
    create_table "sync_instances" do |t|
      t.integer  "site_id"
      t.integer  "owner_id"
      t.integer  "person_id"
      t.integer  "remote_id"
      t.integer  "remote_account_id"
      t.string   "account_type", :limit => 25
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
