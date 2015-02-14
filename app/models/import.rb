class Import < ActiveRecord::Base
  belongs_to :person
  has_many :rows, class_name: 'ImportRow'
  scope_by_site_id

  validates :person, :filename, :status, presence: true

  enum status: %w(pending active complete)
end
