class Participation < ActiveRecord::Base
  belongs_to :person
  belongs_to :participation_category
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
end
