class Address < ActiveRecord::Base
  belongs_to :family
  belongs_to :site
  scope_by_site_id

  include Concerns::Geocode
  geocode_with :address, :city, :state, :zip, :country

  enum kind: %i(home work other)

  validates :kind, presence: true

  after_initialize :set_defaults

  def set_defaults
    self.country = Setting.get(:system, :default_country) if country.blank?
  end

  alias_attribute :address, :address1

  def to_s
    return '' if blank?
    I18n.t(
      address2.present? ? 'addresses.formatted.with_address2' : 'addresses.formatted.no_address2',
      as_hash
    )
  end

  def as_hash
    {
      address1:  address1,
      address2:  address2,
      city:      city,
      state:     state,
      zip:       zip,
      short_zip: short_zip,
      country:   country
    }
  end

  def blank?
    as_hash.values.all?(&:blank?)
  end

  def present?
    !blank?
  end

  def mapable?
    latitude.to_f != 0.0 && longitude.to_f != 0.0
  end

  def short_zip
    zip.to_s.split('-').first
  end
end
