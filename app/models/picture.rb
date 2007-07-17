# == Schema Information
# Schema version: 64
#
# Table name: pictures
#
#  id         :integer(11)   not null, primary key
#  event_id   :integer(11)   
#  person_id  :integer(11)   
#  created_at :datetime      
#  cover      :boolean(1)    
#  updated_at :datetime      
#

class Picture < ActiveRecord::Base
  belongs_to :event
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  acts_as_photo 'db/photos/pictures', PHOTO_SIZES
  acts_as_logger LogItem
end
