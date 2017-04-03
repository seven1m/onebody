class Registrant < ActiveRecord::Base
  scope_by_site_id
  belongs_to :registration
  belongs_to :person
  belongs_to :registrant_type
  has_many :extras, as: :object, class_name: 'RegistrationExtra', dependent: :destroy

  validates :registration, presence: true

  serialize :contact_info

  def contact_info
    self[:contact_info] || {}
  end

  def contact_phone=(phone)
    contact_info ||= {}
    contact_info['phone'] = phone
  end

  def contact_address=(address)
    contact_info ||= {}
    contact_info['address'] = address
  end

  def to_react
    {
      id: id,
      person: person.as_json,
      first_name: first_name,
      last_name: last_name,
      registrant_type_id: registrant_type_id,
      registrant_type: registrant_type.to_react,
      contact_info: contact_info
    }
  end
end
