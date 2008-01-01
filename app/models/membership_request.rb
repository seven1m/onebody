# == Schema Information
# Schema version: 89
#
# Table name: membership_requests
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  group_id   :integer       
#  created_at :datetime      
#

class MembershipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  def after_create
    Notifier.deliver_membership_request(group, person)
  end
end
