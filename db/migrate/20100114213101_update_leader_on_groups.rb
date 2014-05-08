class UpdateLeaderOnGroups < ActiveRecord::Migration
  def self.up
    Site.each do
      Group.where(leader_id: nil).each do |group|
        group.leader = group.admins.first
        group.save(:validate => false)
      end
    end
  end

  def self.down
    # none
  end
end
