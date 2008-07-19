class AddSiteToTwitterMessage < ActiveRecord::Migration
  def self.up
    change_table :twitter_messages do |t|
      t.integer :site_id
    end
  end

  def self.down
    change_table :twitter_messages do |t|
      t.remove :site_id
    end
  end
end
