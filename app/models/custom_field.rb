class CustomField < ActiveRecord::Base
  scope_by_site_id

  validates :name, presence: true
  validates :format, inclusion: %w(string number boolean date select)
  validates :kind, inclusion: %w(person registration)

  belongs_to :customizable, polymorphic: true

  has_many :custom_field_values, foreign_key: 'field_id', dependent: :delete_all

  serialize :options

  scope :for_people, -> { where(kind: 'person') }
  scope :for_registrations, -> { where(kind: 'registration') }

  def slug
    "field#{id}_#{slugged_name}"
  end

  def slugged_name
    name.gsub(/[^a-z0-9]+/i, '')
  end

  def to_react
    {
      name: name,
      format: format,
      options: options
    }
  end
end
