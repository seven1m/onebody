class ImportAttribute < ActiveRecord::Base
  belongs_to :row, class_name: 'ImportRow'
  scope_by_site_id
end
