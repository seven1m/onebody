class Tag < ActiveRecord::Base
  belongs_to :verse
  has_and_belongs_to_many :verses
  has_and_belongs_to_many :recipes
end
