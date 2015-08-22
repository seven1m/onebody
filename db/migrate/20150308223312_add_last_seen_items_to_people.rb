class AddLastSeenItemsToPeople < ActiveRecord::Migration
  def change
    change_table :people do |t|
      t.references :last_seen_stream_item
      t.references :last_seen_group
    end
  end
end
