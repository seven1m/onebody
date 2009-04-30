class UpdateNewsItems < ActiveRecord::Migration
  def self.up
    change_table :news_items do |t|
      t.rename :published, :created_at
      t.string :source
      t.integer :person_id
      t.integer :sequence
      t.datetime :expires_at
    end
    change_table :admins do |t|
      t.boolean :manage_news, :default => false
    end
  end

  def self.down
    change_table :news_items do |t|
      t.rename :created_at, :published
      t.remove :source, :person_id, :sequence, :expires_at
    end
    change_table :admins do |t|
      t.remove :manage_news
    end
  end
end
