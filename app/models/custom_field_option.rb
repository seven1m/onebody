class CustomFieldOption < ActiveRecord::Base
  scope_by_site_id

  validates :label, :field, presence: true

  belongs_to :field, class_name: 'CustomField', inverse_of: :custom_field_options
end
