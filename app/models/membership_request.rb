# == Schema Information
# Schema version: 86
#
# Table name: membership_requests
#
#  id         :integer(11)   not null, primary key
#  person_id  :integer(11)   
#  group_id   :integer(11)   
#  created_at :datetime      
#

class MembershipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  def after_create
    Notifier.deliver_membership_request(group, person)
  end
end
