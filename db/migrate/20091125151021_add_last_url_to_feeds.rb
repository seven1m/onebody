class AddLastUrlToFeeds < ActiveRecord::Migration
  def self.up
    change_table :feeds do |t|
      t.string :last_url, :limit => 1000
    end
  end

  def self.down
    change_table :feeds do |t|
      t.remove :last_url
    end
  end
end
