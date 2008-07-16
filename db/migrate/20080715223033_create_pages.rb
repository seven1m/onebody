class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :slug
      t.string :title
      t.text :body
      t.integer :parent_id
      t.string :path
      t.boolean :published, :default => true
      t.integer :site_id
      t.timestamps
    end
    add_index :pages, :path
    add_index :pages, :parent_id
    change_table :admins do |t|
      t.boolean :edit_pages, :default => false
    end
    change_table :attachments do |t|
      t.remove :song_id
      t.integer :page_id
    end
  end

  def self.down
    change_table :attachments do |t|
      t.integer :song_id
      t.remove :page_id
    end
    change_table :admins do |t|
      t.remove :edit_pages
    end
    remove_index :pages, :path
    remove_index :pages, :parent_id
    drop_table :pages
  end
end
