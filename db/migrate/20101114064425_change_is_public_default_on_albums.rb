class ChangeIsPublicDefaultOnAlbums < ActiveRecord::Migration
  def self.up
    change_column_default :albums, :is_public, false
  end

  def self.down
    change_column_default :albums, :is_public, true
  end
end
