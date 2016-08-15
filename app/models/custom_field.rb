class CustomField < ActiveRecord::Base
  scope_by_site_id

  validates :name, presence: true
  validates :format, inclusion: %w(string number boolean)
end
