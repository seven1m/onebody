# == Schema Information
# Schema version: 76
#
# Table name: friendship_requests
#
#  id         :integer(11)   not null, primary key
#  person_id  :integer(11)   
#  from_id    :integer(11)   
#  rejected   :boolean(1)    
#  created_at :datetime      
#

class FriendshipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :from, :class_name => 'Person', :foreign_key => 'from_id'
  
  validates_presence_of :person_id
  validates_presence_of :from_id
  validates_uniqueness_of :person_id, :scope => :from_id
  
  def validate
    errors.add(:person, 'must have a valid email address') unless person.valid_email?
    errors.add(:person, 'does not accept friend requests') unless person.friends_enabled
  end

  after_create :send_request
  def send_request
    Notifier.deliver_friend_request(from, person)
  end
end
