# == Schema Information
#
# Table name: people
#
#  id                           :integer       not null, primary key
#  family_id                    :integer       
#  sequence                     :integer       
#  gender                       :string(6)     
#  first_name                   :string(255)   
#  last_name                    :string(255)   
#  mobile_phone                 :string(25)    
#  work_phone                   :string(25)    
#  fax                          :string(25)    
#  birthday                     :datetime      
#  email                        :string(255)   
#  website                      :string(255)   
#  classes                      :text          
#  shepherd                     :string(255)   
#  mail_group                   :string(1)     
#  encrypted_password           :string(100)   
#  activities                   :text          
#  interests                    :text          
#  music                        :text          
#  tv_shows                     :text          
#  movies                       :text          
#  books                        :text          
#  quotes                       :text          
#  about                        :text          
#  testimony                    :text          
#  share_mobile_phone           :boolean       
#  share_work_phone             :boolean       
#  share_fax                    :boolean       
#  share_email                  :boolean       
#  share_birthday               :boolean       
#  business_name                :string(100)   
#  business_description         :text          
#  business_phone               :string(25)    
#  business_email               :string(255)   
#  business_website             :string(255)   
#  legacy_id                    :integer       
#  email_changed                :boolean       
#  suffix                       :string(25)    
#  anniversary                  :datetime      
#  updated_at                   :datetime      
#  alternate_email              :string(255)   
#  email_bounces                :integer       default(0)
#  business_category            :string(100)   
#  get_wall_email               :boolean       default(TRUE)
#  account_frozen               :boolean       
#  wall_enabled                 :boolean       
#  messages_enabled             :boolean       default(TRUE)
#  business_address             :string(255)   
#  flags                        :string(255)   
#  visible                      :boolean       default(TRUE)
#  parental_consent             :string(255)   
#  admin_id                     :integer       
#  friends_enabled              :boolean       default(TRUE)
#  member                       :boolean       
#  staff                        :boolean       
#  elder                        :boolean       
#  deacon                       :boolean       
#  can_sign_in                  :boolean       
#  visible_to_everyone          :boolean       
#  visible_on_printed_directory :boolean       
#  full_access                  :boolean       
#  legacy_family_id             :integer       
#  feed_code                    :string(50)    
#  share_activity               :boolean       
#  site_id                      :integer       
#  can_pick_up                  :string(100)   
#  cannot_pick_up               :string(100)   
#  medical_notes                :string(200)   
#  twitter_account              :string(100)   
#  api_key                      :string(50)    
#  salt                         :string(50)    
#  deleted                      :boolean       
#  child                        :boolean       
#  custom_type                  :string(100)   
#  custom_fields                :text          
#  signin_count                 :integer       default(0)
#

class Person < ActiveRecord::Base
  
  MAX_TO_BATCH_AT_A_TIME = 50

  BASICS = %w(first_name last_name suffix mobile_phone work_phone fax city state zip birthday anniversary gender address1 address2 city state zip)
  EXTRAS = %w(email alternate_email website business_category business_name business_description business_phone business_email business_website business_address activities interests music tv_shows movies books quotes about testimony twitter_account)

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
  has_many :recipes, :order => 'title'
  has_many :notes, :order => 'created_at desc'
  has_many :updates, :order => 'created_at'
  has_many :pending_updates, :class_name => 'Update', :foreign_key => 'person_id', :order => 'created_at', :conditions => ['complete = ?', false]
  has_and_belongs_to_many :verses
  has_many :log_items
  has_many :stream_items
  has_many :friendships
  has_many :friends, :class_name => 'Person', :through => :friendships
  has_many :friendship_requests
  has_many :pending_friendship_requests, :class_name => 'FriendshipRequest', :conditions => ['rejected = ?', false]
  has_many :relationships, :dependent => :delete_all
  has_many :related_people, :class_name => 'Person', :through => :relationships
  has_many :inward_relationships, :class_name => 'Relationship', :foreign_key => 'related_id', :dependent => :delete_all
  has_many :inward_related_people, :class_name => 'Person', :through => :inward_relationships
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :attendance_records
  has_many :feeds
  has_many :stream_items
  belongs_to :site
    
  scope_by_site_id
  
  named_scope :unsynced_to_donortools, lambda { {:conditions => ["synced_to_donortools = ? and deleted = ? and (child = ? or birthday <= ?)", false, false, false, 18.years.ago]} }
    
  acts_as_password
  has_one_photo :path => "#{DB_PHOTO_PATH}/people", :sizes => PHOTO_SIZES
    
  acts_as_logger LogItem, :ignore => %w(signin_count)
  
  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :loggable_type => 'Person', :loggable_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  attr_protected :api_key, :feed_code

  validates_presence_of :first_name, :last_name
  validates_length_of :password, :minimum => 5, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_confirmation_of :password, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :alternate_email, :allow_nil => true, :scope => :deleted, :unless => Proc.new { |p| p.deleted? }
  validates_uniqueness_of :feed_code, :allow_nil => true
  validates_format_of :website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/
  validates_format_of :business_website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/
  validates_format_of :business_email, :allow_nil => true, :allow_blank => true, :with => VALID_EMAIL_ADDRESS
  validates_format_of :alternate_email, :allow_nil => true, :allow_blank => true, :with => VALID_EMAIL_ADDRESS
  validates_inclusion_of :gender, :in => %w(Male Female), :allow_nil => true
  
  # validate that an email address is unique to one family (family members may share an email address)
  # validate that an email address is properly formatted
  validates_each [:email, :child] do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any? and not record.deleted?
      if Person.count('*', :conditions => ["#{sql_lcase('email')} = ? and family_id != ? and id != ?", value.downcase, record.family_id, record.id]) > 0
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
  
  inherited_attributes    :share_mobile_phone, :share_work_phone, :share_fax, :share_email, :share_birthday, :share_activity, :wall_enabled, :parent => :family
  fall_through_attributes :home_phone, :address, :address1, :address2, :city, :state, :zip, :short_zip, :mapable?, :to => :family
  fall_through_attributes :share_home_phone, :share_home_phone?, :share_address, :share_address?, :share_anniversary, :share_anniversary?, :to => :family
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
      when 'Recipe', 'Picture', 'Verse'
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
      admin?(:manage_messages) or what.person == self or (what.group and what.group.admin? self) or what.wall_id == self.id
    when 'PrayerRequest'
      admin?(:manage_groups) or what.person == self or (what.group and self.member_of?(what.group))
    when 'RemoteAccount'
      can_edit?(what.person)
    when 'Album'
      admin?(:manage_pictures) or (what.person_id == self.id)
    when 'Picture'
      admin?(:manage_pictures) or (what.album and can_edit?(what.album)) or what.person_id == self.id
    when 'Recipe'
      self == what.person or self.admin?(:manage_recipes)
    when 'Note'
      self == what.person or self.admin?(:manage_notes)
    when 'Comment'
      self == what.person or self.admin?(:manage_comments)
    when 'Page'
      self.admin?(:edit_pages)
    when 'Attachment'
      (what.page and self.can_edit?(what.page)) or (what.message and self.can_edit?(what.message))
    when 'NewsItem'
      self.admin?(:manage_news) or (what.person and what.person == self )
    else
      raise "Unrecognized argument to can_edit? (#{what.inspect})"
    end
  end
  
  def can_sign_in?
    read_attribute(:can_sign_in) and consent_or_13?
  end
  
  def full_access?
    read_attribute(:full_access) or admin? or staff? or elder? or deacon?
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
  
  def at_least_13?; at_least?(13); end
  def adult?; at_least?(18); end
  
  def parental_consent?; parental_consent.to_s.any?; end
  def consent_or_13?; at_least_13? or parental_consent?; end
  
  def visible?(fam=nil)
    fam ||= self.family
    fam and fam.visible? and read_attribute(:visible) and consent_or_13? and visible_to_everyone?
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
    admin and admin.super_admin?
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
      family.people.select { |p| p.adult? and [1, 2].include? p.sequence }
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
    end while Person.count('*', :conditions => ['feed_code = ?', code]) > 0
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
    elsif params[:person] and (BASICS.detect { |a| params[:person][a] } or params[:family])
      self.email = params[:person].delete(:email) # no 'update' necessary for email
      self.save if changed.include?('email')
      if Person.logged_in.can_edit_profile?
        params[:family] ||= {}
        params[:family][:legacy_id] = params[:person][:legacy_family_id] if params[:person][:legacy_family_id]
        params[:person].cleanse(:birthday, :anniversary)
        update_attributes(params[:person]) && family.update_attributes(params[:family])
      else
        params[:person].delete(:family_id)
        Update.create_from_params(params, self)
        self
      end
    elsif params[:freeze] and Person.logged_in.admin?(:edit_profiles)
      if Person.logged_in == self
        self.errors.add_to_base('Cannot freeze your own account.')
        false
      else
        toggle!(:account_frozen)
      end
    elsif params[:person] # testimony, about, favorites, etc.
      update_attributes params[:person].reject { |k, v| !EXTRAS.include?(k) }
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
      self.write_attribute(:email_changed, true)
      Notifier.deliver_email_update(self)
    end
  end
  
  def calendar_accounts(include_family=false)
    cals = groups.all(
  	  :conditions => "gcal_private_link != '' and gcal_private_link is not null",
  	  :select     => "groups.id, groups.gcal_private_link"
  	).map { |g| g.gcal_account }
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
      "http://www.google.com/calendar/embed?showTitle=0&amp;showDate=1&amp;showPrint=1&amp;showTz=0&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;#{src}&amp;ctz=UTC#{Time.zone.utc_offset}"
	  else 
	    nil
	  end
  end
  
  def shared_stream_items(count=30, mine=false)
    enabled_types = []
    enabled_types << 'Message' # wall posts and group posts (not personal messages)
    enabled_types << 'NewsItem'    if Setting.get(:features, :news_page   )
    enabled_types << 'Publication' if Setting.get(:features, :publications)
    enabled_types << 'Verse'       if Setting.get(:features, :verses      )
    enabled_types << 'Album'       if Setting.get(:features, :pictures    )
    enabled_types << 'Note'        if Setting.get(:features, :notes       )
    enabled_types << 'Recipe'      if Setting.get(:features, :recipes     )
    enabled_types << 'PrayerRequest'
    conditions = [
      "stream_items.streamable_type in (?)",
      enabled_types
    ]
    if mine
      conditions.add_condition([
        "(stream_items.person_id = ? or stream_items.wall_id = ?) and " +
        "(stream_items.group_id is null or (groups.hidden = ? and groups.private = ? and stream_items.streamable_type != 'Message'))",
        id,
        id,
        false,
        false
      ])
    else
      friend_ids = all_friend_and_groupy_ids
      group_ids = groups.find_all_by_hidden(false, :select => 'groups.id').map { |g| g.id }
      group_ids = [0] unless group_ids.any?
      conditions.add_condition([
        "stream_items.shared = ? and " +
        "(stream_items.group_id in (?) or " +
        " (stream_items.wall_id is null and stream_items.person_id in (?) and stream_items.streamable_type != 'PrayerRequest') or " +
        " (stream_items.wall_id in (?) and stream_items.person_id in (?)) or " +
        " stream_items.person_id = ? or " +
        " stream_items.wall_id = ? or " +
        " stream_items.streamable_type in ('NewsItem', 'Publication')) and " +
        "(stream_items.group_id is null or (groups.hidden = ? and groups.private = ?))",
        true,
        group_ids,
        friend_ids,
        friend_ids,
        friend_ids,
        id,
        id,
        false,
        false
      ])
    end
    stream_items = StreamItem.all(
      :conditions => conditions,
      :order => 'stream_items.created_at desc',
      :limit => count,
      :include => [:person, :wall, :group]
    )
    # do our own eager loading here...
    comment_people_ids = stream_items.map { |s| s.context['comments'].to_a.map { |c| c['person_id'] } }.flatten
    comment_people = Person.all(
      :conditions => ["id in (?)", comment_people_ids],
      :select => 'first_name, last_name, suffix, gender, id, family_id, updated_at' # only what's needed
    ).inject({}) { |h, p| h[p.id] = p; h } # as a hash with id as the key
    stream_items.each do |stream_item|
      stream_item.context['comments'].to_a.each do |comment|
        comment['person'] = comment_people[comment['person_id']]
      end
      stream_item.readonly!
    end
    stream_items
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
  
  def group_names
    groups.map { |g| g.name }.join(', ')
  end
  
  def update_relationships_hash
    rels = relationships.all(:include => :related).map do |relationship|
      "#{relationship.related.legacy_id}[#{relationship.name_or_other}]"
    end.sort
    self.relationships_hash = Digest::SHA1.hexdigest(rels.join(','))
  end
  
  def update_relationships_hash!
    update_relationships_hash
    save(false)
  end
  
  def update_donor
    Donortools::Persona.setup_connection
    if donor = donortools_id && (Donortools::Persona.find(donortools_id) rescue nil)
      donor.names[0].first_name         = first_name
      donor.names[0].last_name          = last_name
      donor.names[0].suffix             = suffix
      donor.addresses[0].street_address = family.address
      donor.addresses[0].city           = family.city
      donor.addresses[0].state          = family.state
      donor.addresses[0].postal_code    = family.zip
      phone_numbers = [
        {:phone_number => family.home_phone, :address_type_id => 1},
        {:phone_number => work_phone,        :address_type_id => 2},
        {:phone_number => mobile_phone,      :address_type_id => 4}
      ].select { |ph| ph[:phone_number].to_s.any? }
      donor.update_phone_numbers(phone_numbers)
      donor.email_addresses[0].email_address = email
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
    save(false)
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
              person.write_attribute(:email_changed, false) # clear the flag
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
          if record['relationships'] and record['relationships_hash'] != person.relationships_hash
            person.relationships.destroy_all
            record['relationships'].split(',').each do |relationship|
              if relationship =~ /(\d+)\[([^\]]+)\]/ and related = Person.find_by_legacy_id($1)
                person.relationships.create(
                  :related    => related,
                  :name       => 'other',
                  :other_name => $2
                )
              end
            end
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
      find_by_sql("select distinct business_category from people where business_category is not null and business_category != '' order by business_category").map { |p| p.business_category }
    end
  
    def custom_types
      find_by_sql("select distinct custom_type from people where custom_type is not null and custom_type != '' order by custom_type").map { |p| p.custom_type }
    end
    
    def send_to_mongo
      db = Report.db
      people = db['people_new']
      find_each do |person|
        next if person.deleted?
        h = person.to_mongo_hash
        h['admin'] = person.admin ? person.admin.to_mongo_hash : nil
        h['family'] = person.family.to_mongo_hash
        h['groups'] = []
        person.memberships.all(:include => :group).each do |membership|
          gh = membership.group.to_mongo_hash
          gh['membership'] = membership.to_mongo_hash
          h['groups'] << gh
        end
        people.insert(h)
      end
      db['people'].drop
      db['people_new'].rename('people')
      db['people'].count
    end
  
  end

  # model extensions
  Dir["#{Rails.root}/app/models/person/*.rb"].each do |ext|
    load(ext)
    mod_name = ext.split('/').last.split('.').first.classify
    class_eval "include Person::#{mod_name}"
  end

end
