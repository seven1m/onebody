# == Schema Information
# Schema version: 74
#
# Table name: prayer_requests
#
#  id          :integer(11)   not null, primary key
#  group_id    :integer(11)   
#  person_id   :integer(11)   
#  title       :string(100)   
#  body        :text          
#  answer      :text          
#  answered_at :datetime      
#  created_at  :datetime      
#  updated_at  :datetime      
#

class PrayerRequest < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  
  validates_length_of :title, :maximum => 100
end
