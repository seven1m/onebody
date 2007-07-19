class ChangeGroupAttributes < ActiveRecord::Migration
  def self.up
    rename_column :groups, :archived, :hidden
    begin
      Group.find_all_by_subscription(true).each { |g| g.update_attribute :hidden, true }
    rescue
      # subscription doesn't exist ???
    end
    remove_column :groups, :subscription
    if pub = Group.find_by_name('Publications')
      pub.hidden = true
      pub.save
    end
  end

  def self.down
    rename_column :groups, :hidden, :archived
    add_column :groups, :subscription, :boolean, :default => false
  end
end
