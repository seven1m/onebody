class CustomField < ActiveRecord::Base
  scope_by_site_id

  validates :name, presence: true
  validates :format, inclusion: %w(string number boolean date select)

  has_many :custom_field_values, foreign_key: 'field_id', dependent: :delete_all
  has_many :custom_field_options, foreign_key: 'field_id', dependent: :delete_all

  def slug
    "field#{id}_#{slugged_name}"
  end

  def slugged_name
    name.gsub(/[^a-z0-9]+/i, '')
  end
end
