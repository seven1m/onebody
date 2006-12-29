class CreatePerformances < ActiveRecord::Migration
  def self.up
    create_table :performances do |t|
      t.column :setlist_id, :integer
      t.column :song_id, :integer
      t.column :ordering, :integer
    end
  end

  def self.down
    drop_table :performances
  end
end
