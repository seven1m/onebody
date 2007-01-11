class Comment < ActiveRecord::Base
  belongs_to :verse
  belongs_to :person
  has_many :actions
  
  def name
    "Comment on #{verse.reference}"
  end
  
  acts_as_logger LogItem
  
  def admin?(person)
    person.admin? or self.person == person
  end
end
