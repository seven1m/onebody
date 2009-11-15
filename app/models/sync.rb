class Sync < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id
  
  belongs_to :person
  has_many :sync_items, :dependent => :delete_all
  has_many :people,   :through => :sync_items, :source => :syncable, :source_type => 'Person'
  has_many :families, :through => :sync_items, :source => :syncable, :source_type => 'Family'
  has_many :groups,   :through => :sync_items, :source => :syncable, :source_type => 'Group'
end
