class AddStartedAtAndFinishedAtToSyncs < ActiveRecord::Migration
  def self.up
    change_table :syncs do |t|
      t.datetime :started_at, :finished_at
    end
    Sync.reset_column_information
    Site.each do
      Sync.update_all "started_at = created_at, finished_at = updated_at"
    end
  end

  def self.down
    change_table :syncs do |t|
      t.remove :started_at, :finished_at
    end
  end
end
