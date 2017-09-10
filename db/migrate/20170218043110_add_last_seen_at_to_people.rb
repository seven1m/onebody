class AddLastSeenAtToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :last_seen_at, :datetime
  end
end
