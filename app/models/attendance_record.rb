# == Schema Information
# Schema version: 20080724143144
#
# Table name: attendance_records
#
#  id          :integer       not null, primary key
#  site_id     :integer       
#  person_id   :integer       
#  group_id    :integer       
#  attended_at :datetime      
#  created_at  :datetime      
#  updated_at  :datetime      
#

class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  acts_as_logger LogItem
  
  validates_presence_of :person_id
  validates_presence_of :group_id
  validates_presence_of :attended_at
end
