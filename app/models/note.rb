# == Schema Information
# Schema version: 63
#
# Table name: notes
#
#  id           :integer(11)   not null, primary key
#  person_id    :integer(11)   
#  title        :string(255)   
#  body         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  original_url :string(255)   
#  deleted      :boolean(1)    
#

class Note < ActiveRecord::Base
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  acts_as_logger LogItem
  
  validates_presence_of :title
  validates_presence_of :body
end
