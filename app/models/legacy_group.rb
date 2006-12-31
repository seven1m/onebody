class LegacyGroup < ActiveRecord::Base
  set_table_name 'groups_legacy'
  has_many :members, :class_name => 'LegacyGroupMember', :foreign_key => 'group_id'
  
  class << self
    def import_legacy_groups
      find_all_by_deleted(false).each do |g|
        unless Group.find_by_name(g.name)
          puts g.name
          group = Group.create!(
            :name => g.name,
            :description => g.description,
            :meets => g.meets,
            :location => g.location,
            :directions => g.directions,
            :notes => g.notes,
            :category => g.group_type,
            :address => g.list_address.to_s.any? ? g.list_address.split('@').first : nil,
            :members_send => !g.only_friends,
            :link_code => g.link_code
          )
          g.members.each do |m|
            if m.person
              group.memberships.create :person => m.person
            end
          end
        end
      end
    end
  end
end

class LegacyGroupMember < ActiveRecord::Base
  set_table_name 'groupmembers'
  belongs_to :legacy_group
  def person
    Person.find_by_legacy_id(member_id)
  end
end