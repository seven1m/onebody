class MakeAlbumOwner < ActiveRecord::Migration
  def up
    change_table :albums do |t|
      t.integer :owner_id
      t.string :owner_type
    end

    Site.each do
      Album.find_each do |album|
        if album.person_id
          album[:owner_type] = 'Person'
          album[:owner_id] = album.person_id
        elsif album.group_id
          album[:owner_type] = 'Group'
          album[:owner_id] = album.group_id
        end
        album.save!(validate: false)
      end
    end

    change_table :albums do |t|
      t.remove :person_id
      t.remove :group_id
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
