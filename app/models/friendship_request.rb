class FriendshipRequest < ApplicationRecord
  belongs_to :person
  belongs_to :from, class_name: 'Person', foreign_key: 'from_id'
  belongs_to :site

  scope_by_site_id

  validates :person, presence: true, uniqueness: { scope: %i(site_id from_id) }
  validates :from, presence: true

  validate :validate_email_on_target

  def validate_email_on_target
    errors.add(:person, :invalid_address) unless person && person.email.present?
  end

  validate :validate_friends_enabled_on_target

  def validate_friends_enabled_on_target
    errors.add(:person, :refused) unless person && person.friends_enabled
  end

  after_create :send_request
  def send_request
    Notifier.friend_request(from, person).deliver_now
  end

  def accept
    raise 'Only target can accept friendship' unless Person.logged_in == person
    person.friendships.create!(friend: from)
    destroy
  end

  def reject
    raise 'Only target can reject friendship' unless Person.logged_in == person
    update_attribute(:rejected, true)
  end
end
