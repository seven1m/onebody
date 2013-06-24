class Person
  module Groupy

    # TODO rename "sidebar group people" to something more descriptive
    # Basically, people who are likely to be in a small group with another person 

    def sidebar_groups
      @sidebar_groups ||= self.groups.where("(select count(*) from memberships where group_id=groups.id) <= #{MAX_PEOPLE_IN_SMALL_GROUP}").all
    end

    def sidebar_group_people(limit=nil)
      if sidebar_groups.any?
        Person.all(
          conditions: "people.id != #{self.id} and memberships.group_id in (#{sidebar_groups.map { |g| g.id }.join(',')})",
          joins: :memberships,
          limit: limit
        )
      else
        []
      end
    end

    def sidebar_group_people_count
      if sidebar_groups.any?
        Person.count(
          '*',
          conditions: "people.id != #{self.id} and memberships.group_id in (#{sidebar_groups.map { |g| g.id }.join(',')})",
          joins: :memberships
        )
      else
        0
      end
    end

    def random_sidebar_group_people(count=MAX_GROUPIES_ON_PROFILE)
      sidebar_group_people(count).sort_by{rand}
    end
  end
end
