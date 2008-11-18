class ParticipationCategory < ActiveRecord::Base
  has_many :participations, :dependent => :destroy
  has_many :people, :through => :participations
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
end
