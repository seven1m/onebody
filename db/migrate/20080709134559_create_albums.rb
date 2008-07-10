class CreateAlbums < ActiveRecord::Migration
  def self.up
    create_table :albums do |t|
      t.string :name
      t.text :description
      t.integer :person_id
      t.integer :site_id
      t.timestamps
    end
    change_table :pictures do |t|
      t.integer :album_id
    end
    Site.each do |site|
      Picture.all.each do |picture|
        name, description, person_id = \
          picture.connection.select_one(['select name, description, person_id from events where id = ?', picture.event_id])
        album = Album.find_or_initialize_by_name(name)
        album.update_attributes! :description => description, :person_id => person_id
        picture.album = album
        picture.save!
      end
    end
    drop_table :events_verses
    drop_table :events
    change_table :admins do |t|
      t.remove :manage_events
    end
    %w(comments pictures recipes).each do |name|
      change_table name do |t|
        t.remove :event_id
      end
    end
  end

  def self.down
    raise 'unreversable migration'
  end
end
