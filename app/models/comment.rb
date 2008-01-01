# == Schema Information
# Schema version: 89
#
# Table name: comments
#
#  id           :integer       not null, primary key
#  verse_id     :integer       
#  person_id    :integer       
#  text         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  event_id     :integer       
#  recipe_id    :integer       
#  news_item_id :integer       
#  song_id      :integer       
#  note_id      :integer       
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
