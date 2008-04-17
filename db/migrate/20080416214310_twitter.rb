class Twitter < ActiveRecord::Migration
  def self.up
    create_table :twitter_messages do |t|
      t.integer :twitter_id
      t.integer :twitter_screen_name
      t.integer :person_id
      t.string :message, :limit => 140
      t.string :reply, :limit => 140
      t.timestamps
    end
    add_column :people, :twitter_account, :string, :limit => 100
    Setting.update_all
  end

  def self.down
    Setting.find(:all, :conditions => "name like 'Twitter%'").each { |s| s.destroy }
    remove_column :people, :twitter_account
    drop_table :twitter_messages
  end
end
