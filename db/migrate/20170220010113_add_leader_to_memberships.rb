class AddLeaderToMemberships < ActiveRecord::Migration[4.2]
  def up
    add_column :memberships, :leader, :boolean, default: false

    Membership.reset_column_information

    Site.each do
      Group.find_each do |group|
        next unless (leader_id = group.leader_id)
        next unless (leader = Person.find_by(id: leader_id))
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
        group.leader_id = leader.id
        group.save(validate: false)
      end
    end

    remove_column :memberships, :leader
  end
end
