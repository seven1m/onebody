# == Schema Information
#
# Table name: friendship_requests
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  from_id    :integer       
#  rejected   :boolean       
#  created_at :datetime      
#  site_id    :integer       
#

class FriendshipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :from, :class_name => 'Person', :foreign_key => 'from_id'
  belongs_to :site
  
  scope_by_site_id
  
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
  
  def accept
    raise 'Only target can accept friendship' unless Person.logged_in == self.person
    self.person.friendships.create!(:friend => self.from)
    self.destroy
  end
  
  def reject
    raise 'Only target can reject friendship' unless Person.logged_in == self.person
    self.update_attribute(:rejected, true)
  end
end
