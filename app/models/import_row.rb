class ImportRow < ActiveRecord::Base
  belongs_to :import
  has_many :import_attributes, inverse_of: :row, dependent: :delete_all
  scope_by_site_id
  accepts_nested_attributes_for :import_attributes

  validates :import, :status, :sequence, presence: true

  enum status: %w(pending successful failed)

  def import_attributes_as_hash
    import_attributes.each_with_object({}) do |attr, hash|
      hash[attr.name] = attr.value
    end
  end
end
