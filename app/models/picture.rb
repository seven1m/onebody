class Picture < ActiveRecord::Base
  belongs_to :event
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  acts_as_photo 'db/photos/pictures', PHOTO_SIZES
  acts_as_logger LogItem
end
