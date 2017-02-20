class AddLeaderToMemberships < ActiveRecord::Migration
  def up
    add_column :memberships, :leader, :boolean, default: false

    Membership.reset_column_information

    Site.each do
      Group.find_each do |group|
        next unless (leader = group.leader)
        membership = group.memberships.where(person_id: leader.id).first_or_initialize
        membership.leader = true
        membership.save(validate: false)
      end
    end

    remove_column :groups, :leader_id
  end

  def down
    add_column :groups, :leader_id, :integer

    Membership.reset_column_information

    Site.each do
      Group.find_each do |group|
        leader = group.memberships.leaders.first.try(:person)
        next unless leader
        group.leader = leader
        group.save(validate: false)
      end
    end

    remove_column :memberships, :leader
  end
end
