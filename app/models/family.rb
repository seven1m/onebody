class Family < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'FamilyAuthorizer'

  include Concerns::Reorder

  MAX_TO_BATCH_AT_A_TIME = 50

  has_many :people, -> { order(:position) }, dependent: :destroy, inverse_of: :family
  has_many :updates, -> { order(:created_at) }
  accepts_nested_attributes_for :people

  scope_by_site_id

  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }
  scope :has_printable_people, -> { where('(select count(*) from people where family_id = families.id and status = ? and deleted = ?) > 0', Person.statuses[:active], false) }
  scope :by_barcode, ->(b) { where('barcode_id = ? or alternate_barcode_id = ?', b, b) }

  validates :name, presence: true
  validates :last_name, presence: true

  validates_uniqueness_of :barcode_id, allow_nil: true, scope: %i(site_id deleted), unless: proc { |f| f.deleted? }
  validates_uniqueness_of :alternate_barcode_id, allow_nil: true, scope: %i(site_id deleted), unless: proc { |f| f.deleted? }
  validates_length_of :barcode_id, :alternate_barcode_id, in: 5..50, allow_nil: true
  validates_format_of :barcode_id, :alternate_barcode_id, with: /\A\d+\z/, allow_nil: true
  validates_length_of :country, is: 2, allow_nil: true, allow_blank: true
  validates_attachment_size :photo, less_than: PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :photo, content_type: PAPERCLIP_PHOTO_CONTENT_TYPES

  validates_each %i(barcode_id alternate_barcode_id) do |record, attribute, _value|
    if attribute.to_s == 'barcode_id' && record.barcode_id
      if record.barcode_id == record.alternate_barcode_id
        record.errors.add(attribute, :taken)
      elsif Family.where(alternate_barcode_id: record.barcode_id).exists?
        record.errors.add(attribute, :taken)
      end
    elsif attribute.to_s == 'alternate_barcode_id' && record.alternate_barcode_id
      if Family.where(barcode_id: record.alternate_barcode_id).exists?
        record.errors.add(attribute, :taken)
      end
    end
  end

  def initialize(*args)
    super
    self.country = Setting.get(:system, :default_country) unless country.present?
  end

  def barcode_id=(b)
    write_attribute(:barcode_id, b.presence)
    self.barcode_assigned_at = Time.now if barcode_id_changed?
  end

  def alternate_barcode_id=(b)
    write_attribute(:alternate_barcode_id, b.presence)
    self.barcode_assigned_at = Time.now if barcode_id_changed?
  end

  def address
    address1.to_s + (address2.present? ? "\n#{address2}" : '')
  end

  def mapable?
    latitude.to_f != 0.0 && longitude.to_f != 0.0
  end

  include Concerns::Geocode
  geocode_with :address, :city, :state, :zip, :country

  # not HTML-escaped!
  def pretty_address
    a = ''
    a << address1.to_s   if address1.present?
    a << ", #{address2}" if address2.present?
    if city.present? && state.present?
      a << "\n#{city}, #{state}"
      a << "  #{zip}" if zip.present?
    end
    a
  end

  def short_zip
    zip.to_s.split('-').first
  end

  self.digits_only_for_attributes = [:home_phone]

  def parents
    people.undeleted.reorder(:id).select do |person|
      person.adult? && [1, 2].include?(person.position)
    end
  end

  def children_without_consent
    people.undeleted.reject(&:adult_or_consent?)
  end

  def visible_people
    people.undeleted.select do |person|
      !person.deleted? && (
        Person.logged_in.admin?(:view_hidden_profiles) ||
        person.visible?(self)
      )
    end
  end

  def suggested_relationships
    all_people = people.undeleted.order(:position)
    relations = {
      adult: {
        male: {
          adult: {
            female: 'wife'
          },
          child: {
            male:   'son',
            female: 'daughter'
          }
        },
        female: {
          adult: {
            male: 'husband'
          },
          child: {
            male:   'son',
            female: 'daughter'
          }
        }
      },
      child: {
        male: {
          adult: {
            male:   'father',
            female: 'mother'
          }
        },
        female: {
          adult: {
            male:   'father',
            female: 'mother'
          }
        }
      }
    }
    relationships = {}
    all_people.each_with_index do |person, person_index|
      relationships[person] ||= []
      person_adult = person_index <= 1 && person.adult?
      all_people.each_with_index do |related, related_index|
        related_adult = related_index <= 1 && related.adult?
        r = begin
              relations[person_adult ? :adult : :child][person.gender.to_s.downcase.to_sym][related_adult ? :adult : :child][related.gender.to_s.downcase.to_sym]
            rescue
              nil
            end
        relationships[person] << [related, r] if r
      end
    end
    relationships
  end

  attr_accessor :dont_mark_barcode_id_changed

  before_update :mark_barcode_id_changed
  def mark_barcode_id_changed
    return if dont_mark_barcode_id_changed
    write_attribute(:barcode_id_changed, true) if changed.include?('barcode_id')
  end

  # TODO: would be better to actually have family-level sharing options
  def show_attribute_to?(attribute, who)
    send(attribute).present? &&
      people.undeleted.any? { |p| p.show_attribute_to?(attribute, who) }
  end

  def anniversary_sharable_with(who)
    dates = people.undeleted.adults.limit(2).map do |person|
      person.anniversary if person.show_attribute_to?(:anniversary, who)
    end
    dates.first if dates.all? { |d| d == dates.first }
  end

  def adults
    @adults ||= if new_record?
                  people.select(&:adult?)
                else
                  people.undeleted.adults
    end
  end

  def suggest_name?
    s = suggested_name
    s.present? && s != name.sub(/ and /, ' & ')
  end

  def suggested_name
    if adults.size == 1
      adults.first.name
    elsif adults.size >= 2
      (first, second) = adults.take(2)
      if first.last_name == second.last_name
        key = 'families.name.same_last_name'
      elsif Setting.get(:system, :language) == 'cs'
        key = 'families.name.different_last_names'
        husband = first
        wife = second
        if first.gender == 'Female'
          husband = second
          wife = first
        end
        # In Czech, wife's and family name are usualy extensions of husband's name
        if wife.last_name[husband.last_name]
          key = 'families.name.husband_last_name'
          first = husband
          second = wife
        end
      else
        key = 'families.name.different_last_names'
      end
      I18n.t(key,
             adult1_fname: first.first_name,
             adult1_lname: first.last_name,
             adult1_name:  first.name,
             adult2_fname: second.first_name,
             adult2_lname: second.last_name,
             adult2_name:  second.name)
    end
  end

  def suggested_last_name
    adults.first.try(:last_name)
  end

  alias destroy_for_real destroy
  def destroy
    people.each(&:destroy)
    update_attribute(:deleted, true)
  end

  # Go straight to the database to fetch family details for the Directory Map
  def self.mappable_details
    connection.select_all(
      'select families.id, families.name, families.latitude, families.longitude ' \
      'from families ' \
      'left outer join people on people.family_id = families.id ' \
      "where people.visible = #{Family.connection.quoted_true} " \
      "and families.visible = #{Family.connection.quoted_true} " \
      "and families.deleted = #{Family.connection.quoted_false} " \
      "#{Person.logged_in.admin?(:view_hidden_attributes) ? '' :
          "and people.share_address = #{Family.connection.quoted_true} "}" \
      "and people.status = #{Person.statuses[:active]} " \
      "and families.site_id = #{Site.current.id} " \
      'and coalesce(families.latitude, 0.0) != 0.0 ' \
      'and coalesce(families.longitude, 0.0) != 0.0 ' \
      'group by families.id, families.name, families.latitude, families.longitude'
    ).to_a
  end
end
