class CustomField < ActiveRecord::Base
  scope_by_site_id

  validates :name, presence: true
  validates :format, inclusion: %w(string text number boolean date select)

  has_many :custom_field_values, foreign_key: 'field_id', dependent: :delete_all
  has_many :custom_field_options, -> { order(:sequence, :id) }, foreign_key: 'field_id', dependent: :delete_all

  alias options custom_field_options

  accepts_nested_attributes_for :custom_field_options, allow_destroy: true

  scope :select_fields, -> { where(format: 'select') }

  def slug
    "field#{id}_#{slugged_name}"
  end

  def slugged_name
    name.gsub(/[^a-z0-9]+/i, '')
  end

  def self.select_field_options_lookup_by_label
    select_fields.each_with_object({}) do |f, hash|
      hash[f.id] = f.options.each_with_object({}) do |o, h|
        h[o.label.downcase] = o.id
      end
    end
  end
end
