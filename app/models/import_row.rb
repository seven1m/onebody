class ImportRow < ActiveRecord::Base
  belongs_to :import
  has_many :import_attributes, inverse_of: :row, dependent: :delete_all
  scope_by_site_id
  accepts_nested_attributes_for :import_attributes

  validates :import, :status, :sequence, presence: true

  enum status: %w(pending created updated unchanged blank)

  def import_attributes_as_hash(real_attributes: false)
    import_attributes.each_with_object({}) do |attr, hash|
      key = real_attributes ? import.mappings[attr.name] : attr.name
      hash[key] = attr.value if key
    end
  end

  def match_person
    hash = import_attributes_as_hash(real_attributes: true)
    case import.match_strategy
    when 'by_id_only'
      match_person_by_id(hash)
    when 'by_name'
      match_person_by_name(hash)
    when 'by_contact_info'
      match_person_by_mobile_phone(hash) ||
        match_person_by_email(hash)
    when 'by_name_or_contact_info'
      match_person_by_name(hash) ||
        match_person_by_mobile_phone(hash) ||
        match_person_by_email(hash)
    end
  end

  private

  def match_person_by_id(hash)
    return unless hash['id'].present?
    Person.where(
      id: hash['id']
    ).first
  end

  def match_person_by_legacy_id(hash)
    return unless hash['legacy_id'].present?
    Person.where(
      legacy_id: hash['legacy_id']
    ).first
  end

  def match_person_by_name(hash)
    return unless hash['first_name'].present? && hash['last_name'].present?
    Person.where(
      first_name: hash['first_name'],
      last_name: hash['last_name']
    ).first
  end

  def match_person_by_mobile_phone(hash)
    return unless hash['mobile_phone'].present?
    Person.where(
      mobile_phone: hash['mobile_phone'].digits_only
    ).first
  end

  def match_person_by_email(hash)
    return unless hash['email'].present?
    Person.where(
      email: hash['email'].downcase
    ).first
  end
end
