class Person < ActiveRecord::Base
  include Authority::UserAbilities
  include Authority::Abilities
  self.authorizer_name = 'PersonAuthorizer'

  include Concerns::Person::Administrator
  include Concerns::Person::Child
  include Concerns::Person::EmailChanged
  include Concerns::Person::Export
  include Concerns::Person::Fields
  include Concerns::Person::Friend
  include Concerns::Person::Import
  include Concerns::Person::Memberships
  include Concerns::Person::Password
  include Concerns::Person::Relationships
  include Concerns::Person::Sharing
  include Concerns::Person::Streamable
  include Concerns::Person::TwitterUsername
  include Concerns::Person::LastSeenAt
  include Concerns::DateWriter

  acts_as_list scope: :family

  def self.logged_in
    Thread.current[:logged_in]
  end

  def self.logged_in=(person)
    Thread.current[:logged_in] = person
  end

  belongs_to :family
  belongs_to :admin
  has_many :albums, as: :owner
  has_many :pictures, -> { order(created_at: :desc) }
  has_many :messages
  has_many :updates, -> { order(:created_at) }
  has_many :prayer_signups
  has_and_belongs_to_many :verses
  has_many :log_items
  has_many :stream_items
  has_many :prayer_requests, -> { order(created_at: :desc) }
  has_many :attendance_records
  has_many :generated_files
  has_many :tasks, ->(my) { where('tasks.group_scope is true or tasks.person_id = ? ', my.id) }, through: :groups
  has_many :registrations
  belongs_to :site
  belongs_to :last_seen_stream_item, class_name: 'StreamItem'
  belongs_to :last_seen_group, class_name: 'Group'

  scope_by_site_id

  MINIMAL_ATTRIBUTES = %w(
    id first_name last_name suffix child gender birthday gender deleted
    photo_file_name photo_content_type photo_fingerprint photo_updated_at
  ).freeze

  scope :undeleted,              -> { where(deleted: false) }
  scope :deleted,                -> { where(deleted: true) }
  scope :adults,                 -> { where(child: false) }
  scope :adults_or_have_consent, -> { where("child = ? or coalesce(parental_consent, '') != ''", false) }
  scope :children,               -> { where(child: true) }
  scope :can_sign_in,            -> { undeleted.where(status: Person.statuses.values_at(:pending, :active)) }
  scope :administrators,         -> { undeleted.where('admin_id is not null') }
  scope :minimal,                -> { select(MINIMAL_ATTRIBUTES.map { |a| "people.#{a}" }.join(',')) }
  scope :with_birthday_month,    -> (m) { where('birthday is not null and extract(month from birthday) = ?', m) }

  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  validates :first_name, :last_name,
            presence: true
  validate :validate_password_length
  validates :description,
            length: { maximum: 25 }
  validates :password,
            confirmation: true,
            if: -> { Person.logged_in }
  validates :password, password_strength: true,
            if: -> { Setting.get(:privacy, :require_strong_password) }
  validates :alternate_email,
            uniqueness: { scope: [:site_id, :deleted] },
            allow_nil: true,
            unless: -> (p) { p.deleted? }
  validates :feed_code,
            uniqueness: { scope: :site_id },
            allow_nil: true
  validates :website, :business_website,
            format: { with: %r{\Ahttps?\://.+\z} },
            allow_nil: true,
            allow_blank: true
  validates :email, :alternate_email, :business_email,
            format: { with: VALID_EMAIL_ADDRESS },
            allow_nil: true,
            allow_blank: true
  validates :facebook_url,
            format: { with: %r{\Ahttps?\://www\.facebook\.com/.+\z} },
            allow_nil: true,
            allow_blank: true
  validates :business_category,
            exclusion: { in: ['!'] }
  validates :gender,
            inclusion: { in: %w(Male Female) },
            allow_nil: true
  validates_date_of :birthday, :anniversary, allow_nil: true
  validates_attachment_size :photo, less_than: PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :photo, content_type: PAPERCLIP_PHOTO_CONTENT_TYPES
  validates_associated :family
  validate :validate_email_unique

  def validate_email_unique
    return if email.blank? || deleted?
    return unless Person.undeleted.where(email: email)
                        .where.not(id: id || 0)
                        .where.not(family_id: family_id || 0)
                        .any?
    errors.add :email, :taken
  end

  def validate_password_length
    return unless Person.logged_in
    return if password.nil?
    return if password.length >= Setting.get(:privacy, :minimum_password_characters).to_i
    errors.add :password, 'Password is too short'
  end

  enum status: {
    inactive: 0,
    pending:  1,
    active:   2
  }

  lowercase_attribute :email, :alternate_email

  delegate :home_phone, :address, :address1, :address2, :city, :state, :zip, :short_zip, :mapable?, :parents,
           to: :family, allow_nil: true

  sharable_attributes :home_phone, :mobile_phone, :work_phone, :fax,
                      :email, :birthday, :address, :anniversary, :activity

  self.skip_time_zone_conversion_for_attributes = [:birthday, :anniversary]
  self.digits_only_for_attributes = [:mobile_phone, :work_phone, :fax, :business_phone]

  blank_to_nil :suffix, :can_pick_up, :cannot_pick_up, :classes, :medical_notes

  date_writer :birthday, :anniversary

  after_initialize :guess_last_name, if: -> (p) { p.last_name.nil? }

  def guess_last_name
    return unless family
    self.last_name = family.last_name
  end

  def others_with_same_email
    return [] unless family
    return [] unless email.present?
    family.people.undeleted.where(email: email).where.not(id: id)
  end

  after_save :clear_primary_emailer_on_others

  def clear_primary_emailer_on_others
    return unless family && primary_emailer?
    family.people.undeleted.where(email: email).where.not(id: id).update_all(primary_emailer: false)
  end

  def name
    @name ||= begin
      if deleted?
        '(removed person)'
      elsif suffix
        "#{first_name} #{last_name}, #{suffix}"
      else
        "#{first_name} #{last_name}"
      end
    end
  end

  def name_and_nick
    return name unless self.alias
    "#{name} [#{self.alias}]"
  end

  def formatted_email
    return unless email.present?
    Mail::Address.new(email).tap do |address|
      address.display_name = name
    end
  end

  def inspect
    "<#{id}:#{name}>"
  end

  def able_to_sign_in?
    (active? || pending?) && adult_or_consent? && email.present?
  end

  def messages_enabled?
    read_attribute(:messages_enabled) && email.present?
  end

  def parental_consent?
    parental_consent.present?
  end

  def adult_or_consent?
    adult? || parental_consent?
  end

  def visible?(fam = nil)
    fam ||= family
    fam && fam.visible? && read_attribute(:visible) && adult_or_consent? && (active? || pending?)
  end

  def gender=(g)
    self[:gender] = g.present? ? g.capitalize : nil
  end

  # generates security code for grabbing feed(s) without logging in
  before_create :update_feed_code
  def update_feed_code
    loop do
      self.feed_code = SecureRandom.hex(50)[0...50]
      break unless Person.where(feed_code: feed_code).any?
    end
  end

  def show_attribute_to?(attribute, who)
    send(attribute).present? && share_attribute_with?(attribute, who)
  end

  def share_attribute_with?(attribute, who)
    !respond_to?("share_#{attribute}_with?") || send("share_#{attribute}_with?", who)
  end

  def age_group
    code = classes.to_s.split(',').grep(/\AAG:/).first
    return unless code
    code.match(/\AAG:(.+)$/)[1]
  end

  def attendance_today
    attendance_records.on_date(Date.today).includes(:group).order(:attended_at)
  end

  alias_method :destroy_for_real, :destroy
  def destroy
    run_callbacks :destroy do
      update_attribute(:deleted, true)
      updates.destroy_all
    end
  end

  def record_last_seen_stream_item(stream_item)
    return unless stream_item
    return if stream_item.created_at <= (last_seen_stream_item.try(:created_at) || Time.now)
    update_attribute(:last_seen_stream_item, stream_item)
  end

  def self.new_with_default_sharing(attrs)
    new(HashWithIndifferentAccess.new(attrs).merge(default_sharing_attributes))
  end

  def self.default_sharing_attributes
    {
      share_address:      Setting.get(:privacy, :share_address_by_default),
      share_home_phone:   Setting.get(:privacy, :share_home_phone_by_default),
      share_mobile_phone: Setting.get(:privacy, :share_mobile_phone_by_default),
      share_work_phone:   Setting.get(:privacy, :share_work_phone_by_default),
      share_fax:          Setting.get(:privacy, :share_fax_by_default),
      share_email:        Setting.get(:privacy, :share_email_by_default),
      share_birthday:     Setting.get(:privacy, :share_birthday_by_default),
      share_anniversary:  Setting.get(:privacy, :share_anniversary_by_default)
    }
  end

  def self.business_categories
    where("business_category is not null and business_category != ''")
      .order(:business_category)
      .pluck('distinct business_category')
  end

  def self.custom_types
    where("custom_type is not null and custom_type != ''")
      .order(:custom_type)
      .pluck('distinct custom_type')
  end
end
