class Person
  module Groupy
    def sidebar_groups
      @sidebar_groups ||= Setting.get(:features, :sidebar_group_category) && \
        groups.find_all_by_category(Setting.get(:features, :sidebar_group_category))
    end

    def sidebar_group_people(limit=nil)
      if sidebar_groups.to_a.any?
        Person.all(
          :conditions => "people.id != #{self.id} and memberships.group_id in (#{sidebar_groups.map { |g| g.id }.join(',')})",
          :joins => :memberships,
          :limit => limit
        )
      else
        []
      end
    end
    
    def sidebar_group_people_count
      if sidebar_groups.any?
        Person.count(
          '*',
          :conditions => "people.id != #{self.id} and memberships.group_id in (#{sidebar_groups.map { |g| g.id }.join(',')})",
          :joins => :memberships
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
