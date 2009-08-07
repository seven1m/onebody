class ExternalGroup < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id
  validates_presence_of :name
end
