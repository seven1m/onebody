class Person < ActiveRecord::Base

  MAX_TO_BATCH_AT_A_TIME = 50

  BASICS = %w(first_name last_name suffix mobile_phone work_phone fax city state zip birthday anniversary gender address1 address2 city state zip)
  EXTRAS = %w(description email alternate_email website business_category business_name business_description business_phone business_email business_website business_address activities interests music tv_shows movies books quotes about testimony twitter_account)

  cattr_accessor :logged_in # set in addition to @logged_in (for use by Notifier and other models)

  belongs_to :family
  belongs_to :admin
  belongs_to :donor, :class_name => 'Donortools::Persona', :foreign_key => 'donortools_id'
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :albums
  has_many :pictures, :order => 'created_at desc'
  has_many :messages
  has_many :wall_messages, :class_name => 'Message', :foreign_key => 'wall_id', :order => 'created_at desc'
  has_many :notes, :order => 'created_at desc'
  has_many :updates, :order => 'created_at'
  has_many :pending_updates, :class_name => 'Update', :foreign_key => 'person_id', :order => 'created_at', :conditions => ['complete = ?', false]
  has_many :prayer_signups
  has_and_belongs_to_many :verses
  has_many :log_items
  has_many :stream_items
  has_many :friendships
  has_many :friends, :class_name => 'Person', :through => :friendships do
    def thumbnails
      self.all(:select => 'people.id, people.first_name, people.last_name, people.suffix, people.gender, people.photo_file_name, people.photo_content_type, people.photo_fingerprint', :order => 'people.last_name, people.first_name')
    end
  end
  has_many :friendship_requests
  has_many :pending_friendship_requests, :class_name => 'FriendshipRequest', :conditions => ['rejected = ?', false]
  has_many :relationships, :dependent => :delete_all
  has_many :related_people, :class_name => 'Person', :through => :relationships, :source => :related
  has_many :inward_relationships, :class_name => 'Relationship', :foreign_key => 'related_id', :dependent => :delete_all
  has_many :inward_related_people, :class_name => 'Person', :through => :inward_relationships, :source => :person
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :attendance_records
  has_many :feeds
  has_many :stream_items
  has_many :generated_files
  belongs_to :site

  scope_by_site_id

  attr_accessible :gender, :first_name, :last_name, :suffix, :mobile_phone, :work_phone, :fax, :birthday, :email, :website, :activities, :interests, :music, :tv_shows, :movies, :books, :quotes, :about, :testimony, :share_address, :share_home_phone, :share_mobile_phone, :share_work_phone, :share_fax, :share_email, :share_birthday, :share_anniversary, :business_name, :business_description, :business_phone, :business_email, :business_website, :business_category, :suffx, :anniversary, :alternate_email, :get_wall_email, :wall_enabled, :messages_enabled, :business_address, :visible, :friends_enabled, :share_activity, :twitter_account
  attr_accessible :classes, :shepherd, :mail_group, :legacy_id, :account_frozen, :member, :staff, :elder, :deacon, :can_sign_in, :visible_to_everyone, :visible_on_printed_directory, :full_access, :legacy_family_id, :child, :custom_type, :custom_fields, :medical_notes, :if => Proc.new { Person.logged_in and Person.logged_in.admin?(:edit_profiles) }
  attr_accessible :id, :sequence, :can_pick_up, :cannot_pick_up, :family_id, :if => Proc.new { l = Person.logged_in and l.admin?(:edit_profiles) and l.admin?(:import_data) and Person.import_in_progress }

  scope :unsynced_to_donortools, lambda { {:conditions => ["synced_to_donortools = ? and deleted = ? and (child = ? or birthday <= ?)", false, false, false, 18.years.ago]} }
  scope :can_sign_in, :conditions => {:can_sign_in => true, :deleted => false}

  acts_as_password
  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  acts_as_logger LogItem

  validates_presence_of :first_name, :last_name
  validates_length_of :password, :minimum => 5, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_confirmation_of :password, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :alternate_email, :allow_nil => true, :scope => [:site_id, :deleted], :unless => Proc.new { |p| p.deleted? }
  validates_uniqueness_of :feed_code, :allow_nil => true, :scope => :site_id
  validates_format_of :website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/
  validates_format_of :business_website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/
  validates_format_of :business_email, :allow_nil => true, :allow_blank => true, :with => VALID_EMAIL_ADDRESS
  validates_format_of :alternate_email, :allow_nil => true, :allow_blank => true, :with => VALID_EMAIL_ADDRESS
  validates_inclusion_of :gender, :in => %w(Male Female), :allow_nil => true
  validates_attachment_size :photo, :less_than => PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :photo, :content_type => PAPERCLIP_PHOTO_CONTENT_TYPES

  # validate that an email address is unique to one family (family members may share an email address)
  # validate that an email address is properly formatted
  validates_each [:email, :child] do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any? and not record.deleted?
      if Person.count(:conditions => ["#{sql_lcase('email')} = ? and family_id != ? and id != ? and deleted = ?", value.downcase, record.family_id, record.id, false]) > 0
        record.errors.add attribute, :taken
      end
      if value.to_s.strip !~ VALID_EMAIL_ADDRESS
        record.errors.add attribute, :invalid
      end
    elsif attribute.to_s == 'child' and not record.deleted?
      y = record.years_of_age
      if value == true and y and y >= 13
        record.errors.add attribute, :cannot_be_yes
      elsif value == false and y and y < 13
        record.errors.add attribute, :cannot_be_no
      elsif value.nil? and y.nil?
        record.errors.add attribute, :blank
      end
    end
  end

  def name
    @name ||= begin
      if deleted?
        "(removed person)"
      elsif suffix
        "#{first_name} #{last_name}, #{suffix}" rescue '???'
      else
        "#{first_name} #{last_name}" rescue '???'
      end
    end
  end

  def name_possessive
    name =~ /s$/ ? "#{name}'" : "#{name}'s"
  end

  def first_name_possessive
    first_name =~ /s$/ ? "#{first_name}'" : "#{first_name}'s"
  end

  def inspect
    "<#{name}>"
  end

  serialize :custom_fields

  def custom_fields
    (f = read_attribute(:custom_fields)).is_a?(Array) ? f : []
  end

  def custom_fields=(values)
    if values.nil?
      write_attribute(:custom_fields, [])
    else
      existing_values = read_attribute(:custom_fields) || []
      if values.is_a?(Hash)
        values.each do |key, val|
          existing_values[key.to_i] = typecast_custom_value(val, key.to_i)
        end
      else
        values.each_with_index do |val, index|
          existing_values[index] = typecast_custom_value(val, index)
        end
      end
      write_attribute(:custom_fields, existing_values)
    end
  end

  def typecast_custom_value(val, index)
    if Setting.get(:features, :custom_person_fields)[index] =~ /[Dd]ate/
      Date.parse(val.to_s) rescue nil
    else
      val
    end
  end

  def self.can_create?
    Site.current.max_people.nil? or Person.can_sign_in.count < Site.current.max_people
  end

  def birthday_soon?
    today = Date.today
    birthday and ((birthday.yday()+365 - today.yday()).modulo(365) < BIRTHDAY_SOON_DAYS)
  end

  before_create :generate_salt

  def generate_salt
    self.salt = ActiveSupport::SecureRandom.hex(50)[0...50] unless read_attribute(:salt)
  end

  def salt
    read_attribute(:salt) || generate_salt
  end

  fall_through_attributes :home_phone, :address, :address1, :address2, :city, :state, :zip, :short_zip, :mapable?, :to => :family
  sharable_attributes     :home_phone, :mobile_phone, :work_phone, :fax, :email, :birthday, :address, :anniversary, :activity

  self.skip_time_zone_conversion_for_attributes = [:birthday, :anniversary]
  self.digits_only_for_attributes = [:mobile_phone, :work_phone, :fax, :business_phone]

  def groups_sharing(attribute)
    memberships.find(:all, :conditions => ["share_#{attribute.to_s} = ?", true]).map { |m| m.group }
  end

  def can_see?(*whats)
    whats.select do |what|
      case what.class.name
      when 'Person'
        !what.deleted? and (
          what == self or
          what.family_id == self.family_id or
          admin?(:view_hidden_profiles) or
          staff? or what.visible?
        )
      when 'Family'
        !what.deleted? and (what.visible? or admin?(:view_hidden_profiles))
      when 'Group'
        not (what.hidden? or what.private?) or self.member_of?(what) or what.admin?(self)
      when 'Message'
        what.can_see?(self)
      when 'Attachment'
        what.visible_to?(self)
      when 'PrayerRequest'
        what.person == self or
          (what.group and (self.member_of?(what.group) or what.group.admin?(self)))
      when 'Song'
        what.visible_to?(self)
      when 'Note'
        what.person and can_see?(what.person)
      when 'Picture', 'Verse'
        true
      when 'Album'
        what.is_public? or can_see?(what.person)
      when 'Picture'
        what.album.is_public? or can_see?(what.person)
      else
        raise "Unrecognized argument to can_see? (#{what.inspect})"
      end
    end.length == whats.length
  end

  alias_method :sees?, :can_see?

  def can_edit?(what)
    return false if self.account_frozen?
    case what.class.name
    when 'Group'
      what.admin?(self) or self.admin?(:manage_groups)
    when 'Ministry'
      admin?(:manage_ministries) or what.administrator == self
    when 'Person'
      !what.deleted? and (admin?(:edit_profiles) or (what.family == self.family and self.adult?) or what == self)
    when 'Family'
      !what.deleted? and (admin?(:edit_profiles) or (what == self.family and self.adult?))
    when 'Message'
      what.person == self or (what.group and what.group.admin? self) or what.wall_id == self.id
    when 'PrayerRequest'
      admin?(:manage_groups) or what.person == self or (what.group and self.member_of?(what.group))
    when 'RemoteAccount'
      can_edit?(what.person)
    when 'Album'
      admin?(:manage_pictures) or (what.person_id == self.id)
    when 'Picture'
      admin?(:manage_pictures) or (what.album and can_edit?(what.album)) or what.person_id == self.id
    when 'Note'
      self == what.person or self.admin?(:manage_notes)
    when 'Comment'
      self == what.person or self.admin?(:manage_comments)
    when 'Page'
      self.admin?(:edit_pages)
    when 'Attachment'
      (what.page and self.can_edit?(what.page)) or \
      (what.message and self.can_edit?(what.message)) or \
      (what.group and what.group.admin?(self))
    when 'NewsItem'
      self.admin?(:manage_news) or (what.person and what.person == self )
    when 'Membership'
      self.admin?(:manage_groups) or (what.group and what.group.admin?(self)) or self.can_edit?(what.person)
    else
      raise "Unrecognized argument to can_edit? (#{what.inspect})"
    end
  end

  def can_sign_in?
    read_attribute(:can_sign_in) and adult_or_consent?
  end

  def messages_enabled?
    read_attribute(:messages_enabled) and email.to_s.any?
  end

  def member_of?(group)
    memberships.find_by_group_id(group.id)
  end

  def birthday=(b)
    write_attribute(:birthday, b)
    if y = years_of_age
      self.child = nil
    end
  end

  def at_least?(age) # assumes you won't pass in anything over 18
    (y = years_of_age and y >= age) or child == false
  end

  def age
    birthday && birthday.distance_to(Date.today)
  end

  def years_of_age(on=Date.today)
    return nil unless birthday
    return nil if birthday.year == 1900
    years = on.year - birthday.year
    years -= 1 if on.month < birthday.month
    years -= 1 if on.month == birthday.month and on.day < birthday.day
    years
  end

  def adult?; at_least?(Setting.get(:system, :adult_age).to_i); end

  def parental_consent?; parental_consent.to_s.any?; end
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
    (admin and admin.super_admin?) or global_super_admin?
  end

  def global_super_admin?
    defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL.to_s.any? and email == GLOBAL_SUPER_ADMIN_EMAIL
  end

  def valid_email?
    email.to_s.strip =~ VALID_EMAIL_ADDRESS
  end

  def gender=(g)
    if g.to_s.strip.blank?
      g = nil
    else
      g = g.capitalize
    end
    write_attribute(:gender, g)
  end

  # get the parents/guardians by grabbing people in family sequence 1 and 2 and adult?
  def parents
    if family 
      family.people.select { |p| !p.deleted? and p.adult? and [1, 2].include?(p.sequence) }
    end
  end
  
  def active?
    log_items.count(["created_at >= ?", 1.day.ago]) > 0
  end

  def has_favs?
    %w(activities interests music tv_shows movies books quotes).detect do |fav|
      self.send(fav).to_s.any?
    end ? true : false
  end

  def access_attributes
    self.attributes.keys.grep(/_access$/).reject { |a| a == 'full_access' }
  end

  # generates security code for grabbing feed(s) without logging in
  before_create :update_feed_code
  def update_feed_code
    begin # ensure unique
      code = ActiveSupport::SecureRandom.hex(50)[0...50]
      write_attribute :feed_code, code
    end while Person.count(:conditions => ['feed_code = ?', code]) > 0
  end

  def generate_api_key
    write_attribute :api_key, ActiveSupport::SecureRandom.hex(50)[0...50]
  end

  attr_writer :no_auto_sequence

  before_save :update_sequence
  def update_sequence
    return if @no_auto_sequence
    if family and sequence.nil?
      conditions = ['deleted = ?', false]
      conditions.add_condition ['id != ?', id] unless new_record?
      self.sequence = family.people.maximum(:sequence, :conditions => conditions).to_i + 1
    end
  end

  def update_from_params(params)
    params = HashWithIndifferentAccess.new(params) unless params.is_a? HashWithIndifferentAccess
    if params[:photo_url] and params[:photo_url].length > 7 # not just "http://"
      self.photo = params[:photo_url]
      'photo'
    elsif params[:photo]
      self.photo = params[:photo] == 'remove' ? nil : params[:photo]
      'photo'
    elsif params[:person]
      if Person.logged_in.can_edit_profile?
        params[:family] ||= {}
        params[:family][:legacy_id] = params[:person][:legacy_family_id] if params[:person][:legacy_family_id]
        params[:person].cleanse(:birthday, :anniversary)
        update_attributes(params[:person]) && family.update_attributes(params[:family])
      else
        Update.create_from_params(params, self)
        update_attributes(params[:person].reject { |k, v| !EXTRAS.include?(k) })
      end
    else
      self
    end
  end

  def can_edit_profile?
    admin?(:edit_profiles) or not Setting.get(:features, :updates_must_be_approved)
  end

  def suffix=(s)
    s = nil if s.blank?
    write_attribute(:suffix, s)
  end

  attr_accessor :dont_mark_email_changed

  before_update :mark_email_changed
  def mark_email_changed
    return if dont_mark_email_changed
    if changed.include?('email')
      write_attribute(:email_changed, true)
      Notifier.email_update(self).deliver
    end
  end

  def calendar_accounts(include_family=false)
    cals = groups.all(
      :conditions => "gcal_private_link != '' and gcal_private_link is not null",
      :select     => "groups.id, groups.gcal_private_link"
    ).map { |g| g.gcal_account }.select { |a| a.to_s.any? }
    if include_family
      Person.all(:conditions => ["family_id = ?", family_id]).each do |person|
        cals += person.calendar_accounts
      end
    end
    if Setting.get(:features, :community_google_calendar)
      account = Setting.get(:features, :community_google_calendar).to_s.match(/[a-z0-9]+(@|%40)[a-z\.]+/).to_s.sub(/@/, '%40')
      cals << account
    end
    cals
  end

  def my_calendar(include_family=false)
    cals = calendar_accounts(include_family)
    cals.uniq!
    if cals.any?
      src = cals.map { |c| "src=#{c}" }.join("&amp;")
      "https://www.google.com/calendar/embed?showTitle=0&amp;showDate=1&amp;showPrint=1&amp;showTz=1&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;#{src}&amp;ctz=#{Time.zone.tzinfo.name}"
    end
  end

  def shared_stream_items(count=30)
    enabled_types = []
    enabled_types << 'Message' # wall posts and group posts (not personal messages)
    enabled_types << 'NewsItem'    if Setting.get(:features, :news_page   )
    enabled_types << 'Publication' if Setting.get(:features, :publications)
    enabled_types << 'Verse'       if Setting.get(:features, :verses      )
    enabled_types << 'Album'       if Setting.get(:features, :pictures    )
    enabled_types << 'Note'        if Setting.get(:features, :notes       )
    enabled_types << 'PrayerRequest'
    friend_ids = all_friend_and_groupy_ids
    group_ids = groups.find_all_by_hidden(false, :select => 'groups.id').map { |g| g.id }
    group_ids = [0] unless group_ids.any?
    relation = StreamItem.scoped \
               .where(:streamable_type => enabled_types) \
               .where(:shared => true) \
               .where("(group_id in (:group_ids) or" +
                      " (group_id is null and wall_id is null and person_id in (:friend_ids)) or" +
                      " person_id = :id or" +
                      " streamable_type in ('NewsItem', 'Publication')" +
                      ")", :group_ids => group_ids, :friend_ids => friend_ids, :id => id) \
               .order('created_at desc') \
               .limit(count) \
               .includes(:person, :group)
    relation.to_a.tap do |stream_items|
      # do our own eager loading here...
      comment_people_ids = stream_items.map { |s| Array(s.context['comments']).map { |c| c['person_id'] } }.flatten
      comment_people = Person.where(:id => comment_people_ids) \
                             .select('first_name, last_name, suffix, gender, id, family_id, updated_at, photo_file_name, photo_fingerprint') \
                             .inject({}) { |h, p| h[p.id] = p; h } # as a hash with id as the key
      stream_items.each do |stream_item|
        Array(stream_item.context['comments']).each do |comment|
          comment['person'] = comment_people[comment['person_id']]
        end
        stream_item.readonly!
      end
    end
  end

  def show_attribute_to?(attribute, who)
    send(attribute).to_s.strip.any? and
    (not respond_to?("share_#{attribute}_with?") or
    send("share_#{attribute}_with?", who))
  end

  def all_friend_and_groupy_ids
    if Setting.get(:features, :friends)
      friend_ids = friendships.all(:select => 'friend_id').map { |f| f.friend_id }
    else
      friend_ids = []
    end
    friend_ids + sidebar_group_people.map { |p| p.id }
  end

  def to_liquid; inspect; end

  def age_group
    the_classes = self.classes.to_s.split(',')
    if the_class = the_classes.detect { |c| c =~ /^AG:$/ }
      the_class.match(/^AG:(.+)$/)[1]
    end
  end

  def attendance_today
    today = Date.today
    self.attendance_records.all(
      :conditions => ['attendance_records.attended_at >= ? and attendance_records.attended_at <= ?', today.strftime('%Y-%m-%d 0:00'), today.strftime('%Y-%m-%d 23:59:59')],
      :include    => :group,
      :order      => 'attended_at'
    )
  end

  def update_relationships_hash
    rels = relationships.all(:include => :related).select do |relationship|
      !Setting.get(:system, :online_only_relationships).include?(relationship.name_or_other)
    end.map do |relationship|
      "#{relationship.related.legacy_id}[#{relationship.name_or_other}]"
    end.sort
    self.relationships_hash = Digest::SHA1.hexdigest(rels.join(','))
  end

  def update_relationships_hash!
    update_relationships_hash
    save(:validate => false)
  end

  def update_donor
    Donortools::Persona.setup_connection
    return unless adult?
    if donor = donortools_id && (Donortools::Persona.find(donortools_id) rescue nil)
      donor.names[0].first_name         = first_name
      donor.names[0].last_name          = last_name
      donor.names[0].suffix             = suffix
      if donor.addresses[0]
        donor.addresses[0].street_address = family.address
        donor.addresses[0].city           = family.city
        donor.addresses[0].state          = family.state
        donor.addresses[0].postal_code    = family.zip
      else
        donor.addresses << {
          :street_address => family.address,
          :city           => family.city,
          :state          => family.state,
          :postal_code    => family.zip
        }
      end
      phone_numbers = [
        {:phone_number => family.home_phone, :address_type_id => 1},
        {:phone_number => work_phone,        :address_type_id => 2},
        {:phone_number => mobile_phone,      :address_type_id => 4}
      ].select { |ph| ph[:phone_number].to_s.any? }
      donor.update_phone_numbers(phone_numbers)
      if donor.email_addresses[0]
        donor.email_addresses[0].email_address = email
      else
        donor.email_addresses << {:email_address => email}
      end
    else
      donor = Donortools::Persona.new
      donor.names_attributes = [
        {
          :first_name => first_name,
          :last_name  => last_name,
          :suffix     => suffix
        }
      ]
      donor.addresses_attributes = [
        {
          :street_address => family.address,
          :city           => family.city,
          :state          => family.state,
          :postal_code    => family.zip
        }
      ]
      donor.phone_numbers_attributes = [
        {:phone_number => family.home_phone, :address_type_id => 1},
        {:phone_number => work_phone,        :address_type_id => 2},
        {:phone_number => mobile_phone,      :address_type_id => 4}
      ].select { |p| p[:phone_number].to_s.any? }
      donor.email_addresses_attributes = [
        {:email_address => email}
      ]
    end
    donor.save
    self.donortools_id = donor.id
    self.synced_to_donortools = true
    save(:validate => false)
  end

  def donortools_admin_url
    if donortools_id
      "#{Setting.get('services', 'donor_tools_url').sub(/\/$/, '')}/personas/#{donortools_id}/donations"
    end
  end

  before_save :set_synced_to_donortools
  def set_synced_to_donortools
   if (changed & %w(first_name last_name suffix work_phone mobile_phone email)).any?
     self.synced_to_donortools = false
   end
   true
  end

  alias_method :destroy_for_real, :destroy
  def destroy
    self.update_attribute(:deleted, true)
    self.updates.destroy_all
    self.memberships.destroy_all
    self.friendships.destroy_all
    self.membership_requests.destroy_all
    self.friendship_requests.destroy_all
  end


  class << self

    def new_with_default_sharing(attrs)
      attrs.symbolize_keys! if attrs.respond_to?(:symbolize_keys!)
      attrs.merge!(
        :share_address      => Setting.get(:privacy, :share_address_by_default     ),
        :share_home_phone   => Setting.get(:privacy, :share_home_phone_by_default  ),
        :share_mobile_phone => Setting.get(:privacy, :share_mobile_phone_by_default),
        :share_work_phone   => Setting.get(:privacy, :share_work_phone_by_default  ),
        :share_fax          => Setting.get(:privacy, :share_fax_by_default         ),
        :share_email        => Setting.get(:privacy, :share_email_by_default       ),
        :share_birthday     => Setting.get(:privacy, :share_birthday_by_default    ),
        :share_anniversary  => Setting.get(:privacy, :share_anniversary_by_default )
      )
      new(attrs)
    end

    # used to update a batch of records at one time, for UpdateAgent API
    def update_batch(records, options={})
      raise "Too many records to batch at once (#{records.length})" if records.length > MAX_TO_BATCH_AT_A_TIME
      records.map do |record|
        person = find_by_legacy_id(record['legacy_id'])
        # find the family (by legacy_id, preferably)
        family_id = Family.connection.select_value("select id from families where legacy_id = #{record['legacy_family_id'].to_i} and site_id = #{Site.current.id}")
        if person.nil? and options['claim_families_by_barcode_if_no_legacy_id'] and family_id
          # family should have already been claimed by barcode -- we're just going to try to match up people by name
          # mark all people in this family as deleted, in case we don't get them all matched up
          destroy_all ["family_id = ? and legacy_id is null and deleted = ?", family_id, false]
          family_people = find_all_by_family_id_and_legacy_id(family_id, nil)
          # try to match by name
          person = family_people.detect { |p| p.first_name.soundex == record['first_name'].soundex and p.last_name.soundex == record['last_name'].soundex }
          # it's not a huge deal if someone doesn't get matched up by name (a good percentage won't),
          # because we'll just go ahead and create a new record below anyway (and non-matched ones are marked as deleted)
        end
        # last resort, create a new record
        person ||= new
        person.family_id = family_id
        record.each do |key, value|
          value = nil if value == ''
          # avoid overwriting a newer email address
          if key == 'email' and person.email_changed?
            if value == person.email # email now matches (presumably, the external db has been updated to match the OneBody db)
              person.email_changed = false # clear the flag
            else
              next # don't overwrite the newer email address with an older one
            end
          elsif %w(family email_changed remote_hash relationships relationships_hash).include?(key) # skip these
            next
          end
          person.send("#{key}=", value) # be sure to call the actual method (don't use write_attribute)
        end
        person.dont_mark_email_changed = true # set flag to indicate we're the api
        if person.save
          if record['relationships_hash'] != person.relationships_hash
            person.relationships.all.select do |relationship|
              !Setting.get(:system, :online_only_relationships).include?(relationship.name_or_other)
            end.each { |r| r.delete }
            record['relationships'].to_s.split(',').each do |relationship|
              if relationship =~ /(\d+)\[([^\]]+)\]/ and related = Person.find_by_legacy_id($1)
                person.relationships.create(
                  :related    => related,
                  :name       => 'other',
                  :other_name => $2
                )
              end
            end
            person.update_relationships_hash!
          end
          s = {:status => 'saved', :legacy_id => person.legacy_id, :id => person.id, :name => person.name}
          if person.email_changed? # email_changed flag still set
            s[:status] = 'saved with error'
            s[:error] = "Newer email not overwritten: #{person.email.inspect}"
          end
          s
        else
          {:status => 'not saved', :legacy_id => record['legacy_id'], :id => person.id, :name => person.name, :error => person.errors.full_messages.join('; ')}
        end
      end
    end

    def business_categories
      find_by_sql("select distinct business_category from people where business_category is not null and business_category != '' and site_id = #{Site.current.id} order by business_category").map { |p| p.business_category }
    end

    def custom_types
      find_by_sql("select distinct custom_type from people where custom_type is not null and custom_type != '' and site_id = #{Site.current.id} order by custom_type").map { |p| p.custom_type }
    end

  end

  # model extensions
  Dir["#{Rails.root}/app/models/person/*.rb"].each do |ext|
    load(ext)
    mod_name = ext.split('/').last.split('.').first.classify
    class_eval "include Person::#{mod_name}"
  end

end
