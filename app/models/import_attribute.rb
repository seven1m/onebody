class ImportAttribute < ActiveRecord::Base
  belongs_to :row, class_name: 'ImportRow', foreign_key: 'import_row_id'
  belongs_to :import

  scope_by_site_id

  validates :import, :row, presence: true
end
