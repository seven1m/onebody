class SyncInstance < ActiveRecord::Base
  belongs_to :site
  belongs_to :person
  belongs_to :owner, :class_name => 'Person'
  belongs_to :remote_account
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
end
