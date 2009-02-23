class BlogItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :bloggable, :polymorphic => true
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  validates_inclusion_of :bloggable_type, :in => %w(Verse Recipe Note Picture)
end
