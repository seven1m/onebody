class AddMessageTypeToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :message_type, :string, :limit => 10
    Group.update_all "message_type = 'forum'"
  end

  def self.down
    remove_column :groups, :message_type
  end
end
