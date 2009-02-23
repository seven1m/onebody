class CreateBlogItems < ActiveRecord::Migration
  def self.up
    create_table :blog_items do |t|
      t.integer :site_id
      t.string :name, :limit => 255
      t.text :body
      t.integer :album_id
      t.integer :person_id
      t.references :bloggable, :polymorphic => true
      t.datetime :created_at
    end
    # update log_items (we added 'name' and 'deleted' later, so some older log items don't have updated values)
    Site.each do
      LogItem.all(:conditions => "loggable_type in ('Verse', 'Note', 'Recipe', 'Picture') and name is null").each do |log_item|
        if log_item.object
          log_item.name = log_item.object.name
        else
          log_item.deleted = true
        end
        log_item.save
      end
    end
    # create blog_items
    Site.each do
      LogItem.find(
        :all,
        :conditions => ["deleted = ? and group_id is null and loggable_type in (?)", false, %w(Verse Recipe Note Picture)]
      ).each do |log_item|
        log_item.create_as_blog_item
      end
    end
  end

  def self.down
    drop_table :blog_items
  end
end
