class Person
  module Groupy
    def sidebar_groups
      Setting.get(:features, :sidebar_group_category) && \
        groups.find_all_by_category(Setting.get(:features, :sidebar_group_category))
    end

    def sidebar_group_people(order='people.last_name, people.first_name', limit=nil)
      if sidebar_groups.any?
        Person.find(:all, :conditions => "people.id != #{self.id} and memberships.group_id in (#{sidebar_groups.map { |g| g.id }.join(',')})", :joins => :memberships, :order => order, :limit => limit).uniq
      else
        []
      end
    end

    def random_sidebar_group_people(count=MAX_GROUPIES_ON_PROFILE)
      sidebar_group_people(sql_random, count)
    end
  end
end