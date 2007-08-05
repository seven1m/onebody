# == Schema Information
# Schema version: 78
#
# Table name: prayer_requests
#
#  id          :integer(11)   not null, primary key
#  group_id    :integer(11)   
#  person_id   :integer(11)   
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
