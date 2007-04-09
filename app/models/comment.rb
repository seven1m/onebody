class Comment < ActiveRecord::Base
  belongs_to :person
  belongs_to :verse
  belongs_to :event
  belongs_to :recipe
  belongs_to :news_item
  belongs_to :song
  #belongs_to :picture # not for now
  
  def on
    verse || event || recipe || news_item || song
  end
  
  def name
    "Comment on #{on.name}"
  end
  
  acts_as_logger LogItem
  
  def admin?(person)
    person.admin? or self.person == person
  end
end
