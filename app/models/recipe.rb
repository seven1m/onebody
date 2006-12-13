class Recipe < ActiveRecord::Base

  belongs_to :person
  has_and_belongs_to_many :tags
  
  validates_presence_of :title
  validates_presence_of :ingredients
  validates_presence_of :directions
  
  acts_as_photo 'db/photos/recipes', PHOTO_SIZES
  
  def admin?(person)
    person == self.person or person.admin?
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

end
