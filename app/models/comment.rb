# == Schema Information
#
# Table name: comments
#
#  id           :integer       not null, primary key
#  verse_id     :integer       
#  person_id    :integer       
#  text         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  recipe_id    :integer       
#  news_item_id :integer       
#  song_id      :integer       
#  note_id      :integer       
#  site_id      :integer       
#  picture_id   :integer

class Comment < ActiveRecord::Base
  belongs_to :person
  belongs_to :verse
  belongs_to :recipe
  belongs_to :note
  belongs_to :picture
  belongs_to :site

  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
    
  def on
    verse || recipe || note || picture
  end
  
  def name
    "Comment on #{on ? on.name : '?'}"
  end
    
  acts_as_logger LogItem
end
