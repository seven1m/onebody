class ServiceCategory < ActiveRecord::Base
  has_many :services, :dependent => :destroy
  has_many :people, :through => :services
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
end
