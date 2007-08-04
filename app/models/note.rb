# == Schema Information
# Schema version: 78
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
#  group_id     :integer(11)   
#

class Note < ActiveRecord::Base
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  belongs_to :group
  has_many :comments, :dependent => :destroy
  
  acts_as_logger LogItem
  
  validates_presence_of :title
  validates_presence_of :body
  
  def name; title; end
end
