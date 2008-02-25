# == Schema Information
# Schema version: 1
#
# Table name: pictures
#
#  id         :integer       not null, primary key
#  event_id   :integer       
#  person_id  :integer       
#  created_at :datetime      
#  cover      :boolean       
#  updated_at :datetime      
#  site_id    :integer       
#

class Picture < ActiveRecord::Base
  belongs_to :event
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  acts_as_photo 'db/photos/pictures', PHOTO_SIZES
  acts_as_logger LogItem
end
