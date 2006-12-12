class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :name, :string, :limit => 50
    end
    create_table :tags_verses, :id => false do |t|
      t.column :tag_id, :integer
      t.column :verse_id, :integer
    end
    create_table :recipes_tags, :id => false do |t|
      t.column :tag_id, :integer
      t.column :recipe_id, :integer
    end
  end

  def self.down
    drop_table :tags
    drop_table :tags_verses
    drop_table :tags_recipes
  end
end
