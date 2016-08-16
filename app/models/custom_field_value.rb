class CustomFieldValue < ActiveRecord::Base
  scope_by_site_id

  belongs_to :object, polymorphic: true
  belongs_to :field, class_name: 'CustomField'
end
