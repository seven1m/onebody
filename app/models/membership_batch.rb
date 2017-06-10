class MembershipBatch
  def initialize(group, ids)
    @group = group
    @ids = Array(ids)
  end

  def delete_requests
    @group.membership_requests.where(person_id: @ids).delete_all
  end

  def create
    @ids.map do |id|
      if (person = Person.undeleted.find(id)) && !person.member_of?(@group)
        @group.memberships.create(person: person)
      end
    end.compact
  end

  def delete
    @ids.each do |id|
      if membership = @group.memberships.where(person_id: id).first
        membership.destroy unless membership.only_admin?
      end
    end
  end
end
