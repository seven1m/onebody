# == Schema Information
# Schema version: 74
#
# Table name: comments
#
#  id           :integer(11)   not null, primary key
#  verse_id     :integer(11)   
#  person_id    :integer(11)   
#  text         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  event_id     :integer(11)   
#  recipe_id    :integer(11)   
#  news_item_id :integer(11)   
#  song_id      :integer(11)   
#

class Comment < ActiveRecord::Base
  belongs_to :person
  belongs_to :verse
  belongs_to :event
  belongs_to :recipe
  belongs_to :news_item
  belongs_to :song
  belongs_to :note
  #belongs_to :picture # not for now
    
  def on
    verse || event || recipe || news_item || song || note
  end
  
  def name
    "Comment on #{on.name}"
  end
    
  acts_as_logger LogItem
  
  def admin?(person)
    person.admin?(:manage_comments) or self.person == person
  end
end
