class AddLastSeenAtToPeople < ActiveRecord::Migration
  def change
    add_column :people, :last_seen_at, :datetime
  end
end
