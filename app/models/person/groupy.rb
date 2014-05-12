require 'active_support/concern'

class Person
  module Groupy
    extend ActiveSupport::Concern

    # TODO rename "sidebar group people" to something more descriptive
    # Basically, people who are likely to be in a small group with another person

    included do
      scope :in_groups, -> groups { joins(:memberships).where('memberships.group_id in (?)', groups.map(&:id)) }
    end

    def sidebar_groups
      @sidebar_groups ||= self.groups.where("(select count(*) from memberships where group_id=groups.id) <= #{MAX_PEOPLE_IN_SMALL_GROUP}")
    end

    def sidebar_group_people(limit=nil)
      if sidebar_groups.any?
        Person.in_groups(sidebar_groups).where('people.id != ?', self.id).limit(limit)
      else
        []
      end
    end

    def sidebar_group_people_count
      if sidebar_groups.any?
        Person.in_groups(sidebar_groups).where('people.id != ?', self.id).count
      else
        0
      end
    end

    def random_sidebar_group_people(count=MAX_GROUPIES_ON_PROFILE)
      sidebar_group_people(count).sort_by{rand}
    end
  end
end
