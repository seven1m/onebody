# == Schema Information
# Schema version: 20080724143144
#
# Table name: friendships
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  friend_id  :integer       
#  created_at :datetime      
#  ordering   :integer       default(1000)
#  site_id    :integer       
#

class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class_name => 'Person', :foreign_key => 'friend_id'
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  validates_presence_of :person_id
  validates_presence_of :friend_id
  validates_uniqueness_of :friend_id, :scope => :person_id
  
  acts_as_logger LogItem
  
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
