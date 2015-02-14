class ImportRow < ActiveRecord::Base
  belongs_to :import
  has_many :import_attributes, inverse_of: :row
  scope_by_site_id
  accepts_nested_attributes_for :import_attributes

  validates :import, :status, :sequence, presence: true

  enum status: %w(pending successful failed)
end
