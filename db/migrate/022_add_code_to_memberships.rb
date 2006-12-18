class AddCodeToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :code, :integer
    Membership.find(:all).each { |m| m.before_create; m.save }
  end

  def self.down
    remove_column :memberships, :code
  end
end
