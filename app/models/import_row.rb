class ImportRow < ActiveRecord::Base
  belongs_to :import, touch: true
  belongs_to :person
  belongs_to :family

  validates :import, :sequence, presence: true

  scope_by_site_id

  scope :created_person,     -> { where(created_person: true) }
  scope :created_family,     -> { where(created_family: true) }
  scope :updated_person,     -> { where(updated_person: true) }
  scope :updated_family,     -> { where(updated_family: true) }
  scope :unchanged_people,   -> { where(created_person: false, updated_person: false) }
  scope :unchanged_families, -> { where(created_family: false, updated_family: false) }
  scope :errored,            -> { where(errored: true) }

  enum status: %w(
    parsed
    previewed
    imported
  )

  enum matched_person_by: {
    matched_person_by_id: 1,
    matched_person_by_name: 2,
    matched_person_by_contact_info: 3,
    matched_person_by_legacy_id: 4
  }

  enum matched_family_by: {
    matched_family_by_id: 1,
    matched_family_by_name: 2,
    matched_family_by_contact_info: 3,
    matched_family_by_legacy_id: 4
  }

  serialize :import_attributes, JSON
  serialize :attribute_changes, JSON
  serialize :attribute_errors, JSON

  def import_attributes_attributes=(attrs)
    self.import_attributes = attrs.each_with_object({}) do |attr, hash|
      attr.stringify_keys!
      hash[attr['name']] = attr['value']
    end
  end

  def import_attributes_as_hash(real_attributes: false, keep_invalid: false)
    import_attributes.each_with_object({}) do |(key, value), hash|
      real_key = import.mappings[key]
      next unless valid_key?(real_key) || keep_invalid
      if real_attributes
        hash[real_key] = value
      else
        hash[key] = value
      end
    end
  end

  def valid_key?(key)
    return false if key.blank?
    @importable_column_names ||= Person.importable_column_names
    @importable_column_names.include?(key)
  end

  def match_person
    hash = import_attributes_as_hash(real_attributes: true)
    case import.match_strategy
    when 'by_id_only'
      match_person_by_id(hash) ||
        match_person_by_legacy_id(hash)
    when 'by_name'
      match_person_by_id(hash) ||
        match_person_by_legacy_id(hash) ||
        match_person_by_name(hash)
    when 'by_contact_info'
      match_person_by_id(hash) ||
        match_person_by_legacy_id(hash) ||
        match_person_by_mobile_phone(hash) ||
        match_person_by_email(hash)
    when 'by_name_or_contact_info'
      match_person_by_id(hash) ||
        match_person_by_legacy_id(hash) ||
        match_person_by_name(hash) ||
        match_person_by_mobile_phone(hash) ||
        match_person_by_email(hash)
    end
  end

  def match_family
    hash = import_attributes_as_hash(real_attributes: true)
    case import.match_strategy
    when 'by_id_only'
      match_family_by_id(hash) ||
        match_family_by_legacy_id(hash)
    when 'by_name'
      match_family_by_id(hash) ||
        match_family_by_legacy_id(hash) ||
        match_family_by_name(hash)
    when 'by_contact_info'
      match_family_by_id(hash) ||
        match_family_by_legacy_id(hash) ||
        match_family_by_home_phone(hash) ||
        match_family_by_address(hash)
    when 'by_name_or_contact_info'
      match_family_by_id(hash) ||
        match_family_by_legacy_id(hash) ||
        match_family_by_name(hash) ||
        match_family_by_home_phone(hash) ||
        match_family_by_address(hash)
    end
  end

  def reset_statuses
    self.created_person    = false
    self.created_family    = false
    self.updated_person    = false
    self.updated_family    = false
    self.matched_person_by = nil
    self.matched_family_by = nil
    self.person            = nil
    self.family            = nil
    self.attribute_errors  = {}
  end

  private

  def match_person_by_id(hash)
    return unless hash['id'].present?
    return unless (person = people.where(id: hash['id']).first)
    self.matched_person_by = :matched_person_by_id
    person
  end

  def match_person_by_legacy_id(hash)
    return unless hash['legacy_id'].present?
    return unless (person = people.where(legacy_id: hash['legacy_id']).first)
    self.matched_person_by = :matched_person_by_legacy_id
    person
  end

  def match_person_by_name(hash)
    return unless hash['first_name'].present? && hash['last_name'].present?
    attrs = { first_name: hash['first_name'], last_name: hash['last_name'] }
    return unless (person = people.where(attrs).first)
    self.matched_person_by = :matched_person_by_name
    person
  end

  def match_person_by_mobile_phone(hash)
    return unless hash['mobile_phone'].present?
    return unless (person = people.where(mobile_phone: hash['mobile_phone'].digits_only).first)
    self.matched_person_by = :matched_person_by_contact_info
    person
  end

  def match_person_by_email(hash)
    return unless hash['email'].present?
    return unless (person = people.where(email: hash['email'].downcase).first)
    self.matched_person_by = :matched_person_by_contact_info
    person
  end

  def match_family_by_id(hash)
    return unless hash['family_id'].present?
    return unless (family = families.where(id: hash['family_id']).first)
    self.matched_family_by = :matched_family_by_id
    family
  end

  def match_family_by_legacy_id(hash)
    legacy_id = hash['family_legacy_id'] || hash['legacy_family_id']
    return unless legacy_id.present?
    return unless (family = families.where(legacy_id: legacy_id).first)
    self.matched_family_by = :matched_family_by_legacy_id
    family
  end

  def match_family_by_name(hash)
    return unless hash['family_name'].present?
    return unless (family = families.where(name: hash['family_name']).first)
    self.matched_family_by = :matched_family_by_name
    family
  end

  def match_family_by_home_phone(hash)
    return unless hash['family_home_phone'].present?
    return unless (family = families.where(home_phone: hash['family_home_phone'].digits_only).first)
    self.matched_family_by = :matched_family_by_contact_info
    family
  end

  def match_family_by_address(hash)
    return unless hash['family_address1'].present?
    return unless hash['family_city'].present?
    return unless hash['family_state'].present?
    return unless hash['family_zip'].present?
    family = families.where('lower(address1) = ?', hash['family_address1'].downcase)
                     .where('lower(city)     = ?', hash['family_city'].downcase)
                     .where('lower(state)    = ?', hash['family_state'].downcase)
                     .where('lower(zip)      = ?', hash['family_zip'].downcase)
                     .first
    return unless family
    self.matched_family_by = :matched_family_by_contact_info
    family
  end

  def people
    Person.undeleted
  end

  def families
    Family.undeleted
  end
end
