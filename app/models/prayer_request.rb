# == Schema Information
# Schema version: 4
#
# Table name: prayer_requests
#
#  id          :integer       not null, primary key
#  group_id    :integer       
#  person_id   :integer       
#  request     :text          
#  answer      :text          
#  answered_at :datetime      
#  created_at  :datetime      
#  updated_at  :datetime      
#  site_id     :integer       
#

class PrayerRequest < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_logger LogItem
  
  def name; "Prayer Request in #{group.name}"; end
end
