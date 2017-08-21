class MembershipRequest < ApplicationRecord
  belongs_to :person
  belongs_to :group
  belongs_to :site

  validates_uniqueness_of :group_id, scope: %i(site_id person_id)

  scope_by_site_id

  after_create :deliver

  def deliver
    Notifier.membership_request(group, person).try(:deliver)
  end

  validate :validate_duplicate_membership

  def validate_duplicate_membership
    if Membership.where(group_id: group_id, person_id: person_id).first
      errors.add(:base, 'Already a member of this group.')
    end
  end
end
