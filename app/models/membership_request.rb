# == Schema Information
# Schema version: 20080709134559
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
  
  validates_uniqueness_of :group_id, :scope => :person_id
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def after_create
    Notifier.deliver_membership_request(group, person)
  end
  
  def validate
    if Membership.find_by_group_id_and_person_id(group_id, person_id)
      errors.add_to_base('Already a member of this group.')
    end
  end
end
