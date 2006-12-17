class AddUpdatedAtToAll < ActiveRecord::Migration
  def self.up
    add_column :people, :updated_at, :datetime
    add_column :families, :updated_at, :datetime
    add_column :groups, :updated_at, :datetime
    add_column :memberships, :updated_at, :datetime
    add_column :contacts, :updated_at, :datetime
    add_column :pictures, :updated_at, :datetime
    add_column :events, :updated_at, :datetime
    add_column :verifications, :updated_at, :datetime
    add_column :ministries, :updated_at, :datetime
    add_column :publications, :updated_at, :datetime
    add_column :verses, :updated_at, :datetime
    add_column :tags, :updated_at, :datetime
    add_column :comments, :updated_at, :datetime
  end

  def self.down
    remove_column :people, :updated_at
    remove_column :families, :updated_at
    remove_column :groups, :updated_at
    remove_column :memberships, :updated_at
    remove_column :contacts, :updated_at
    remove_column :pictures, :updated_at
    remove_column :events, :updated_at
    remove_column :verifications, :updated_at
    remove_column :ministries, :updated_at
    remove_column :publications, :updated_at
    remove_column :verses, :updated_at
    remove_column :tags, :updated_at
    remove_column :comments, :updated_at
  end
end
