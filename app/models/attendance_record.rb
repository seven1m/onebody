# == Schema Information
#
# Table name: attendance_records
#
#  id                :integer       not null, primary key
#  site_id           :integer       
#  person_id         :integer       
#  group_id          :integer       
#  attended_at       :datetime      
#  created_at        :datetime      
#  updated_at        :datetime      
#  external_group_id :integer       
#  first_name        :string(255)   
#  last_name         :string(255)   
#  family_name       :string(255)   
#  age               :string(255)   
#  can_pick_up       :string(100)   
#  cannot_pick_up    :string(100)   
#  medical_notes     :string(200)   
#

class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site
  scope_by_site_id
  
  validates_presence_of :person_id
  validates_presence_of :group_id
  validates_presence_of :attended_at
  
  self.skip_time_zone_conversion_for_attributes = [:attended_at]
end
