# == Schema Information
#
# Table name: group_times
#
#  id              :integer       not null, primary key
#  group_id        :integer       
#  checkin_time_id :integer       
#  ordering        :integer       
#  created_at      :datetime      
#  updated_at      :datetime      
#

class GroupTime < ActiveRecord::Base
  belongs_to :group
  belongs_to :checkin_time
  
  scope_by_site_id
end
