# == Schema Information
#
# Table name: recipes
#
#  id           :integer       not null, primary key
#  person_id    :integer       
#  title        :string(255)   
#  notes        :text          
#  description  :text          
#  ingredients  :text          
#  directions   :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  prep         :string(255)   
#  bake         :string(255)   
#  serving_size :integer       
#  site_id      :integer       
#

class Recipe < ActiveRecord::Base

  has_many :comments, :dependent => :destroy
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  has_and_belongs_to_many :tags
  belongs_to :site
  
  scope_by_site_id
  
  validates_presence_of :title
  validates_presence_of :ingredients
  validates_presence_of :directions
    
  has_one_photo :path => "#{DB_PHOTO_PATH}/recipes", :sizes => PHOTO_SIZES
  acts_as_logger LogItem
  acts_as_taggable
  
  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :loggable_type => 'Recipe', :loggable_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  def name; title; end
  
  def body; description; end
  
  # not needed any more?
  def admin?(person)
    person.can_edit?(self)
  end

  def tag_string=(text)
    text.split.each do |tag_name|
      tag = Tag.find_or_create_by_name(tag_name.downcase)
      tags << tag if not tags.include? tag
    end
    tags
  end
  
  def ingredients=(text)
    write_attribute :ingredients, Recipe.convert_entities(text)
  end
  
  def directions=(text)
    write_attribute :directions, Recipe.convert_entities(text)
  end
  
  CONVERSIONS = {
    '1/4' => '&frac14;',
    '1/2' => '&frac12;',
    '3/4' => '&frac34;',
    '1/3' => '&#8531;',
    '2/3' => '&#8532;',
    '1/5' => '&#8533;',
    '2/5' => '&#8534;',
    '3/5' => '&#8535;',
    '4/5' => '&#8536;',
    '1/6' => '&#8537;',
    '5/6' => '&#8538;',
    '1/8' => '&#8539;',
    '3/8' => '&#8540;',
    '5/8' => '&#8541;',
    '7/8' => '&#8542;'
  }
  
  class << self
    def convert_entities(text)
      CONVERSIONS.each do |raw, entity|
        text.gsub! Regexp.new(' ?'+raw), entity
      end
      text
    end
  end
  
  after_create :create_as_stream_item
  
  def create_as_stream_item
    return unless person
    StreamItem.create!(
      :title           => title,
      :body            => description,
      :person_id       => person_id,
      :streamable_type => 'Recipe',
      :streamable_id   => id,
      :created_at      => created_at,
      :shared          => person.share_activity?
    )
  end
  
  after_update :update_stream_items
  
  def update_stream_items
    StreamItem.find_all_by_streamable_type_and_streamable_id('Recipe', id).each do |stream_item|
      stream_item.title = title
      stream_item.body  = description
      stream_item.save
    end
  end
  
  after_destroy :delete_stream_items
  
  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'Recipe', :streamable_id => id)
  end

end
