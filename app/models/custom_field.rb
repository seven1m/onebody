class CustomField < ActiveRecord::Base
  scope_by_site_id

  validates :name, presence: true
  validates :format, inclusion: %w(string number boolean date)

  has_many :custom_field_values, foreign_key: 'field_id', dependent: :delete_all
end
