class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class_name => 'Person', :foreign_key => 'friend_id'
  
  validates_presence_of :person_id
  validates_presence_of :friend_id
end
