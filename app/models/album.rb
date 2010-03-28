# == Schema Information
#
# Table name: albums
#
#  id          :integer       not null, primary key
#  name        :string(255)   
#  description :text          
#  person_id   :integer       
#  site_id     :integer       
#  created_at  :datetime      
#  updated_at  :datetime      
#  group_id    :integer       
#  is_public   :boolean       default(TRUE)
#

class Album < ActiveRecord::Base
  belongs_to :group
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  belongs_to :site
  has_many :pictures, :dependent => :destroy
  
  scope_by_site_id
  
  attr_accessible :name, :description, :is_public
  attr_protected nil
  
  acts_as_logger LogItem
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :person_id
  
  def cover
    @cover ||= pictures.find_by_cover(true)
    @cover ||= pictures.first
  end
  
  after_destroy :delete_stream_items
  
  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'Album', :streamable_id => id)
  end
end
