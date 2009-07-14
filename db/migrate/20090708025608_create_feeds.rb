class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :name, :limit => 100
      t.string :url, :limit => 1000
      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
