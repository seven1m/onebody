# == Schema Information
# Schema version: 63
#
# Table name: friendships
#
#  id        :integer(11)   not null, primary key
#  person_id :integer(11)   
#  friend_id :integer(11)   
#  confirmed :boolean(1)    
#

class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class_name => 'Person', :foreign_key => 'friend_id'
  
  validates_presence_of :person_id
  validates_presence_of :friend_id
end
