# == Schema Information
# Schema version: 4
#
# Table name: membership_requests
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  group_id   :integer       
#  created_at :datetime      
#  site_id    :integer       
#

class MembershipRequest < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  def after_create
    Notifier.deliver_membership_request(group, person)
  end
end
