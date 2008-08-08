# == Schema Information
#
# Table name: tags
#
#  id         :integer       not null, primary key
#  name       :string(50)    
#  updated_at :datetime      
#  site_id    :integer       
#

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :recipes
  has_and_belongs_to_many :songs
  belongs_to :site
  
  has_many :taggings
  has_many :verses,  :through => :taggings, :conditions => "taggings.taggable_type = 'Verse'"
  has_many :recipes, :through => :taggings, :conditions => "taggings.taggable_type = 'Recipe'"
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_exclusion_of :name, :in => %w(edit new delete destroy create update index)
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_logger LogItem
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false
    
  def to_param
    self.name
  end
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end
end
