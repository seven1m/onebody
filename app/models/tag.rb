# == Schema Information
# Schema version: 78
#
# Table name: tags
#
#  id         :integer(11)   not null, primary key
#  name       :string(50)    
#  updated_at :datetime      
#

class Tag < ActiveRecord::Base
  belongs_to :verse
  has_and_belongs_to_many :verses
  has_and_belongs_to_many :recipes
  #has_and_belongs_to_many :groups
  has_and_belongs_to_many :songs
  acts_as_logger LogItem
end
