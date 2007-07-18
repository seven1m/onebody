class FriendshipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :from, :class_name => 'Person', :foreign_key => 'from_id'
  
  validates_presence_of :person_id
  validates_presence_of :from_id
  validates_uniqueness_of :person_id, :scope => :from_id
  
  def validate
    errors.add(:person, 'must have a valid email address') unless person.valid_email?
    errors.add(:person, 'does not accept friend requests') unless person.friendship_requests
  end

  after_create :send_request
  def send_request
    unless person.friendship_requests
      Notifier.deliver_friend_request(from, person)
    end
  end
end
