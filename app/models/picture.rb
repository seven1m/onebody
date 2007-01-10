class Picture < ActiveRecord::Base
  belongs_to :event
  belongs_to :person
  acts_as_photo 'db/photos/pictures', PHOTO_SIZES
  acts_as_logger LogItem
end
