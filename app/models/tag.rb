# == Schema Information
# Schema version: 20080409165237
#
# Table name: tags
#
#  id         :integer       not null, primary key
#  name       :string(50)    
#  updated_at :datetime      
#  site_id    :integer       
#

class Tag < ActiveRecord::Base
  belongs_to :verse
  has_and_belongs_to_many :verses
  has_and_belongs_to_many :recipes
  #has_and_belongs_to_many :groups
  has_and_belongs_to_many :songs
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_logger LogItem
  
  def to_param
    self.name
  end
end
