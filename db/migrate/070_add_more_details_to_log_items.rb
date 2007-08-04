class AddMoreDetailsToLogItems < ActiveRecord::Migration
  def self.up
    # only do this if it's not already done
    add_column :log_items, :name, :string, :limit => 255 rescue nil
    add_column :log_items, :group_id, :integer rescue nil
  end

  def self.down
  end
end
