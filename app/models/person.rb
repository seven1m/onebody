class Person < ActiveRecord::Base
  include Authority::UserAbilities
  include Authority::Abilities
  self.authorizer_name = 'PersonAuthorizer'

  include Concerns::Person::Child
  include Concerns::Person::Password
  include Concerns::Person::Friend
  include Concerns::Person::Sharing
  include Concerns::Person::Import
  include Concerns::Person::Export
  include Concerns::Person::PdfGen
  include Concerns::Person::Batch
  include Concerns::Person::TwitterUsername
  include Concerns::Person::Streamable
  include Concerns::Person::EmailChanged
  include Concerns::Person::Relationships
  include Concerns::Person::Memberships
  include Concerns::DateWriter

  acts_as_list scope: :family

  cattr_accessor :logged_in # set in addition to @logged_in (for use by Notifier and other models)

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
  has_many :tasks
  belongs_to :site

  scope_by_site_id

  scope :undeleted,              -> { where(deleted: false) }
  scope :deleted,                -> { where(deleted: true) }
  scope :adults,                 -> { where(child: false) }
  scope :adults_or_have_consent, -> { where("child = 0 or coalesce(parental_consent, '') != ''") }
  scope :children,               -> { where(child: true) }
  scope :can_sign_in,            -> { undeleted.where(can_sign_in: true) }
  scope :administrators,         -> { undeleted.where('admin_id is not null') }
  scope :minimal,                -> { select('people.id, people.first_name, people.last_name, people.suffix, people.child, people.gender, people.birthday, people.gender, people.photo_file_name, people.photo_content_type, people.photo_fingerprint, people.photo_updated_at, people.deleted') }
  scope :with_birthday_month,    -> m { where('birthday is not null and month(birthday) = ?', m) }

  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  validates :first_name, :last_name,
            presence: true
  validates :password,
            length: { minimum: 5 },
            allow_nil: true,
            if: -> { Person.logged_in }
  validates :description,
            length: { maximum: 25 }
  validates :password,
            confirmation: true,
            if: -> { Person.logged_in }
  validates :alternate_email,
            uniqueness: { scope: [:site_id, :deleted] },
            allow_nil: true,
            unless: -> p { p.deleted? }
  validates :feed_code,
            uniqueness: { scope: :site_id },
            allow_nil: true
  validates :website, :business_website,
            format: { with: /\Ahttps?\:\/\/.+/ },
            allow_nil: true,
            allow_blank: true
  validates :email, :alternate_email, :business_email,
            format: { with: VALID_EMAIL_ADDRESS },
            allow_nil: true,
            allow_blank: true
  validates :facebook_url,
            format: { with: /\Ahttps?\:\/\/www\.facebook\.com\/.+/ },
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
  validate :validate_email_unique

  def validate_email_unique
    return if email.blank? or deleted?
    if Person.undeleted.where(email: email)
                       .where.not(id: id || 0)
                       .where.not(family_id: family_id || 0)
                       .any?
      errors.add :email, :taken
    end
  end

  lowercase_attribute :email, :alternate_email

  delegate             :home_phone, :address, :address1, :address2, :city, :state, :zip, :short_zip, :mapable?, to: :family, allow_nil: true
  sharable_attributes  :home_phone, :mobile_phone, :work_phone, :fax, :email, :birthday, :address, :anniversary, :activity

  self.skip_time_zone_conversion_for_attributes = [:birthday, :anniversary]
  self.digits_only_for_attributes = [:mobile_phone, :work_phone, :fax, :business_phone]

  blank_to_nil :suffix

  date_writer :birthday, :anniversary

  after_initialize :guess_last_name, if: -> p { p.last_name.nil? }

  def guess_last_name
    return unless family
    self.last_name = family.last_name
  end

  def others_with_same_email
    return [] unless family
    family.people.undeleted.where(email: email).where.not(id: id)
  end

  after_save :clear_primary_emailer_on_others

  def clear_primary_emailer_on_others
    return unless family and primary_emailer?
    family.people.undeleted.where(email: email).where.not(id: id).update_all(primary_emailer: false)
  end

  def name
    @name ||= begin
      if deleted?
        "(removed person)"
      elsif suffix
        "#{first_name} #{last_name}, #{suffix}"
      else
        "#{first_name} #{last_name}"
      end
    end
  end

  def formatted_email
    return unless email.present?
    Mail::Address.new(email).tap do |address|
      address.display_name = name
    end
  end

  def inspect
    "<#{name}>"
  end

  def can_sign_in?
    read_attribute(:can_sign_in) and adult_or_consent?
  end

  def messages_enabled?
    read_attribute(:messages_enabled) and email.present?
  end

  def parental_consent?; parental_consent.present?; end
  def adult_or_consent?; adult? or parental_consent?; end

  def visible?(fam=nil)
    fam ||= self.family
    fam and fam.visible? and read_attribute(:visible) and adult_or_consent? and visible_to_everyone?
  end

  def admin?(perm=nil)
    if super_admin?
      true
    elsif perm
      admin and admin.flags[perm.to_s]
    else
      admin ? true : false
    end
  end

  def super_admin?
    admin.try(:super_admin?)
  end

  def gender=(g)
    self[:gender] = g.present? ? g.capitalize : nil
  end

  # get the parents/guardians by grabbing people in family position 1 and 2 and adult?
  def parents
    if family
      family.people.reorder(:id).select do |person|
        !person.deleted? and person.adult? and [1, 2].include?(person.position)
      end
    end
  end

  # generates security code for grabbing feed(s) without logging in
  before_create :update_feed_code
  def update_feed_code
    begin # ensure unique
      self.feed_code = SecureRandom.hex(50)[0...50]
    end while Person.where(feed_code: feed_code).any?
  end

  def show_attribute_to?(attribute, who)
    send(attribute).to_s.strip.any? and
    (not respond_to?("share_#{attribute}_with?") or
    send("share_#{attribute}_with?", who))
  end

  def age_group
    the_classes = self.classes.to_s.split(',')
    if the_class = the_classes.detect { |c| c =~ /^AG:/ }
      the_class.match(/^AG:(.+)$/)[1]
    end
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

  def set_default_visibility
    self.can_sign_in = true
    self.visible_to_everyone = true
    self.visible_on_printed_directory = true
    self.full_access = true
  end

  class << self

    def new_with_default_sharing(attrs)
      attrs.symbolize_keys! if attrs.respond_to?(:symbolize_keys!)
      attrs.merge!(
        share_address:      Setting.get(:privacy, :share_address_by_default     ),
        share_home_phone:   Setting.get(:privacy, :share_home_phone_by_default  ),
        share_mobile_phone: Setting.get(:privacy, :share_mobile_phone_by_default),
        share_work_phone:   Setting.get(:privacy, :share_work_phone_by_default  ),
        share_fax:          Setting.get(:privacy, :share_fax_by_default         ),
        share_email:        Setting.get(:privacy, :share_email_by_default       ),
        share_birthday:     Setting.get(:privacy, :share_birthday_by_default    ),
        share_anniversary:  Setting.get(:privacy, :share_anniversary_by_default )
      )
      new(attrs)
    end

    def business_categories
      connection.select("select distinct business_category as name from people where business_category is not null and business_category != '' and site_id = #{Site.current.id} order by business_category").map { |c| c['name'] }
    end

    def custom_types
      connection.select("select distinct custom_type as name from people where custom_type is not null and custom_type != '' and site_id = #{Site.current.id} order by custom_type").map { |t| t['name'] }
    end

  end
end
