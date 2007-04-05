class ResizeLinkCodeOnGroups < ActiveRecord::Migration
  def self.up
    values = {}
    Group.find(:all).each do |group|
      values[group.id] = group.link_code
    end
    remove_column :groups, :link_code
    add_column :groups, :link_code, :string, :limit => 255
    values.each do |id, code|
      Group.find(id).update_attribute :link_code, code
    end
  end

  def self.down
    # no reason to downsize this column
  end
end
