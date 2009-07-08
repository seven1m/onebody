class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :name, :limit => 100
      t.string :rss_url, :limit => 1000
      t.string :twitter_username, :facebook_uid, :limit => 25
      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
