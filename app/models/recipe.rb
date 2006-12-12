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

end
