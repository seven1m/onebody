# == Schema Information
# Schema version: 89
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
#

class PrayerRequest < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  
  acts_as_logger LogItem
  
  def name; "Prayer Request in #{group.name}"; end
end
