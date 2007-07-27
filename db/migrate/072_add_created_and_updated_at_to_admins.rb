class AddCreatedAndUpdatedAtToAdmins < ActiveRecord::Migration
  def self.up
    add_column :admins, :created_at, :datetime
    add_column :admins, :updated_at, :datetime
  end

  def self.down
    remove_column :admins, :created_at
    remove_column :admins, :updated_at
  end
end
