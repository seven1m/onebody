class ImportRow < ActiveRecord::Base
  belongs_to :import
  has_many :import_attributes
  scope_by_site_id
  accepts_nested_attributes_for :import_attributes
end
