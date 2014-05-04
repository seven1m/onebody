class FriendshipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :from, class_name: 'Person', foreign_key: 'from_id'
  belongs_to :site

  scope_by_site_id

  validates_presence_of :person_id
  validates_presence_of :from_id
  validates_uniqueness_of :person_id, scope: [:site_id, :from_id]

  validate :validate_email_on_target

  def validate_email_on_target
    errors.add(:person, :invalid_address) unless person.valid_email?
  end

  validate :validate_friends_enabled_on_target

  def validate_friends_enabled_on_target
    errors.add(:person, :refused) unless person.friends_enabled
  end

  after_create :send_request
  def send_request
    Notifier.friend_request(from, person).deliver
  end

  def accept
    raise 'Only target can accept friendship' unless Person.logged_in == self.person
    self.person.friendships.create!(friend: self.from)
    self.destroy
  end

  def reject
    raise 'Only target can reject friendship' unless Person.logged_in == self.person
    self.update_attribute(:rejected, true)
  end
end
