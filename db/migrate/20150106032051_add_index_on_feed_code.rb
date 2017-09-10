class AddIndexOnFeedCode < ActiveRecord::Migration[4.2]
  def change
    add_index :people, [:site_id, :feed_code]
  end
end
