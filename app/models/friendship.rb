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
  MIRRORED_ATTRIBUTES = %w(pending rejected initiated_by_id rejected_by_id)
  
  belongs_to :person
  belongs_to :friend, :class_name => 'Person', :foreign_key => 'friend_id'
  belongs_to :initiated_by, :class_name => 'Person', :foreign_key => 'initiated_by_id'
  belongs_to :rejected_by, :class_name => 'Person', :foreign_key => 'rejected_by_id'
  
  validates_presence_of :person_id
  validates_presence_of :friend_id
  validates_uniqueness_of :friend_id, :scope => :person_id
  
  def validate
    # friendship pending and initiated by @logged_in
    # friendship pending and initiated by params[:id]
    # friendship rejected and rejected by @logged_in
    # friendship rejected and rejected by params[:id]
    # no existing friendships
    
  end
  
  attr_accessor :skip_mirror
  
  before_save :mirror_friendship
  def mirror_friendship
    unless skip_mirror
      mirror = Friendship.find_by_person_id(friend_id) || Friendship.new(:person_id => friend_id)
      MIRRORED_ATTRIBUTES.each do |attr|
        eval("mirror.#{attr} = self.#{attr}")
      end
      mirror.friend_id = person_id
      mirror.skip_mirror = true
      mirror.save
    end
  end
  
  after_destroy :delete_mirror
  def delete_mirror
    Friendship.find_by_person_id(friend_id).destroy rescue nil
  end
end
