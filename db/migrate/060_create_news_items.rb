class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.column :title, :string, :limit => 255
      t.column :link, :string, :limit => 255
      t.column :body, :text
      t.column :published, :datetime
      t.column :active, :boolean, :default => true
    end
    
    add_column :comments, :news_item_id, :integer
  end

  def self.down
    drop_table :news_items
    remove_column :comments, :news_item_id
  end
end
