class RegistrantType < ActiveRecord::Base
  scope_by_site_id
  belongs_to :event

  has_many :custom_fields, -> { order(:ordering) }, as: :customizable, dependent: :destroy
  has_many :registrant_releases, -> { order(:ordering) }, dependent: :destroy

  validates :event, :name, :base_cost, presence: true

  scope :required, -> { where(required: true) }

  include FlagShihTzu

  has_flags \
    1 => :require_contact_phone,
    2 => :require_contact_address,
    3 => :default_to_user

  def to_react
    {
      id: id,
      name: name,
      description: description,
      required: true,
      flags: {
        require_contact_phone: require_contact_phone,
        require_contact_address: require_contact_address
      },
      registrant_releases: registrant_releases.map(&:to_react),
      custom_fields: custom_fields.map(&:to_react)
    }
  end
end
