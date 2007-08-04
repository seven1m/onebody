# == Schema Information
# Schema version: 78
#
# Table name: events
#
#  id          :integer(11)   not null, primary key
#  person_id   :integer(11)   
#  name        :string(255)   
#  description :text          
#  when        :datetime      
#  created_at  :datetime      
#  open        :boolean(1)    
#  admins      :text          
#  updated_at  :datetime      
#

class Event < ActiveRecord::Base
  has_many :pictures, :order => 'created_at', :dependent => :destroy
  has_many :recipes, :order => 'title', :dependent => :nullify
  has_many :comments, :dependent => :destroy
  has_and_belongs_to_many :verses, :order => 'reference'
  belongs_to :person
  serialize :admins
  
  acts_as_logger LogItem
  
  validates_presence_of :name
  validates_presence_of :when
    
  def cover_picture
    if pictures.count > 0
      pictures.find_all_by_cover(true).first || pictures.last
    end
  end
  
  def admin?(person)
    person == self.person or person.admin?(:manage_events)
  end
end
