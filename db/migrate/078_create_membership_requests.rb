class CreateMembershipRequests < ActiveRecord::Migration
  def self.up
    create_table :membership_requests do |t|
      t.column :person_id, :integer
      t.column :group_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :membership_requests
  end
end
