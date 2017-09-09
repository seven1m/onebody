class MembershipSharingUpdater
  def initialize(user, updates)
    @user = user
    @updates = updates
  end

  def perform
    Array(@updates).each do |membership_id, sharing|
      membership = Membership.find(membership_id)
      verify_authorization(membership)
      sharing.each do |attribute, value|
        next unless attribute =~ /\Ashare_/
        value = false if shared_at_person_level?(membership, attribute)
        membership.attributes = { attribute => value }
      end
      membership.save!
    end
  end

  private

  def verify_authorization(membership)
    raise Authority::SecurityViolation unless membership.updatable_by?(@user)
  end

  def shared_at_person_level?(membership, attribute)
    membership.person.attributes[attribute]
  end
end
