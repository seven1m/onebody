class AddIndexOnFeedCode < ActiveRecord::Migration
  def change
    add_index :people, [:site_id, :feed_code]
  end
end
