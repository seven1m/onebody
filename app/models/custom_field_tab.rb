class CustomFieldTab < ApplicationRecord
  scope_by_site_id

  has_many :fields, class_name: 'CustomField', foreign_key: 'tab_id'

  validates :name, presence: true

  acts_as_list scope: :site_id

  default_scope -> { order(:position) }
end
