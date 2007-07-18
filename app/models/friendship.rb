# == Schema Information
# Schema version: 64
#
# Table name: friendships
#
#  id              :integer(11)   not null, primary key
#  person_id       :integer(11)   
#  friend_id       :integer(11)   
#  pending         :boolean(1)    default(TRUE)
#  rejected        :boolean(1)    
#  initiated_by_id :integer(11)   
#  rejected_by_id  :integer(11)   
#  created_at      :datetime      
#  updated_at      :datetime      
#

class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class_name => 'Person', :foreign_key => 'friend_id'
  
  validates_presence_of :person_id
  validates_presence_of :friend_id
  validates_uniqueness_of :friend_id, :scope => :person_id
  
  attr_accessor :skip_mirror
  
  before_save :mirror_friendship
  def mirror_friendship
    unless skip_mirror
      mirror = Friendship.find_by_person_id(friend_id) || Friendship.new(:person_id => friend_id)
      mirror.friend_id = person_id
      mirror.skip_mirror = true
      mirror.save!
    end
  end
  
  def destroy
    Friendship.delete_all ['(friend_id = ? and person_id = ?) or (friend_id = ? and person_id = ?)', person.id, friend.id, friend.id, person.id]
  end
end
