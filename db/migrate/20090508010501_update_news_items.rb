class UpdateNewsItems < ActiveRecord::Migration
  def self.up
    change_table :news_items do |t|
      t.integer :person_id
      t.timestamps
    end
  end

  def self.down
    change_table :news_items do |t|
      t.remove :person_id, :created_at, :updated_at
    end
  end
end
