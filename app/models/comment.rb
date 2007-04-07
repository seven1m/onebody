class Comment < ActiveRecord::Base
  belongs_to :person
  belongs_to :verse
  belongs_to :event
  belongs_to :recipe
  #belongs_to :picture # not for now
  
  def on
    verse || event || recipe
  end
  
  def name
    "Comment on #{verse.reference}"
  end
  
  acts_as_logger LogItem
  
  def admin?(person)
    person.admin? or self.person == person
  end
end
