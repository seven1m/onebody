class Post < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  
  validates_presence_of :text
end
