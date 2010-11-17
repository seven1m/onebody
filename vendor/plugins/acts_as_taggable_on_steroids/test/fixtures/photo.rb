class Photo < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
end

class SpecialPhoto < Photo
end
