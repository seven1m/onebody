class Event < ActiveRecord::Base
  include Authority::Abilities
  self.authorizer_name = 'EventAuthorizer'

  scope_by_site_id

  has_many :registrations, dependent: :destroy
  has_many :registrants, through: :registrations
  has_many :registrant_types, -> { order(:ordering) }, dependent: :destroy
  has_many :extras, -> { order(:ordering) }, class_name: 'EventExtra', dependent: :destroy
  has_many :discount_rules, dependent: :destroy
  has_many :registrant_releases, -> { order(:ordering) }
  has_many :custom_fields, -> { order(:ordering) }, as: :customizable, dependent: :destroy

  enum visibility: {
    visible_if_logged_in: 1,
    # visible_to_public: 2, # reserved for later use
    logged_in_with_link: 3,
    anyone_with_link: 4,
    archived: 5
  }

  validates :visibility, presence: true

  def open?
    registration_starts_at.nil? ||
      registration_ends_at.nil? ||
      (Time.current >= registration_starts_at && Time.current <= registration_ends_at)
  end

  def to_react
    {
      registrant_types: registrant_types.map(&:to_react),
      extras: extras.map(&:to_react),
      custom_fields: custom_fields.map(&:to_react)
    }
  end
end
