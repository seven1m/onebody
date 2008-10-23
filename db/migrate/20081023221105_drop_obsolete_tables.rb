class DropObsoleteTables < ActiveRecord::Migration
  def self.up
    %w(
      contacts
      feeds
      ministries
      performances
      prayer_signups
      setlists
      songs
      songs_tags
      sync_info
      workers
    ).each { |t| drop_table t }
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert this migration."
  end
end
