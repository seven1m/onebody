# == Schema Information
#
# Table name: people
#
#  id                           :integer(4)    not null, primary key
#  family_id                    :integer(4)    
#  sequence                     :integer(4)    
#  gender                       :string(6)     
#  first_name                   :string(255)   
#  last_name                    :string(255)   
#  mobile_phone                 :string(25)    
#  work_phone                   :string(25)    
#  fax                          :string(25)    
#  birthday                     :datetime      
#  email                        :string(255)   
#  website                      :string(255)   
#  classes                      :string(255)   
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
#  share_mobile_phone           :boolean(1)    
#  share_work_phone             :boolean(1)    
#  share_fax                    :boolean(1)    
#  share_email                  :boolean(1)    
#  share_birthday               :boolean(1)    
#  business_name                :string(100)   
#  business_description         :text          
#  business_phone               :string(25)    
#  business_email               :string(255)   
#  business_website             :string(255)   
#  legacy_id                    :integer(4)    
#  email_changed                :boolean(1)    
#  suffix                       :string(25)    
#  anniversary                  :datetime      
#  updated_at                   :datetime      
#  alternate_email              :string(255)   
#  email_bounces                :integer(4)    default(0)
#  business_category            :string(100)   
#  get_wall_email               :boolean(1)    default(TRUE)
#  account_frozen               :boolean(1)    
#  wall_enabled                 :boolean(1)    
#  messages_enabled             :boolean(1)    default(TRUE)
#  business_address             :string(255)   
#  flags                        :string(255)   
#  visible                      :boolean(1)    default(TRUE)
#  parental_consent             :string(255)   
#  admin_id                     :integer(4)    
#  friends_enabled              :boolean(1)    default(TRUE)
#  member                       :boolean(1)    
#  staff                        :boolean(1)    
#  elder                        :boolean(1)    
#  deacon                       :boolean(1)    
#  can_sign_in                  :boolean(1)    
#  visible_to_everyone          :boolean(1)    
#  visible_on_printed_directory :boolean(1)    
#  full_access                  :boolean(1)    
#  legacy_family_id             :integer(4)    
#  feed_code                    :string(50)    
#  share_activity               :boolean(1)    
#  site_id                      :integer(4)    
#  barcode_id                   :string(50)    
#  can_pick_up                  :string(100)   
#  cannot_pick_up               :string(100)   
#  medical_notes                :string(200)   
#  checkin_access               :boolean(1)    
#  twitter_account              :string(100)   
#  api_key                      :string(50)    
#  salt                         :string(50)    
#  deleted                      :boolean(1)    
#

class Person < ActiveRecord::Base

  BASICS = %w(first_name last_name suffix mobile_phone work_phone fax city state zip birthday anniversary gender address1 address2 city state zip)
  EXTRAS = %w(email website business_category business_name business_description business_phone business_email business_website business_address activities interests music tv_shows movies books quotes about testimony)

  cattr_accessor :logged_in # set in addition to @logged_in (for use by Notifier and other models)
  cattr_accessor :sync_in_progress
  
  belongs_to :family
  belongs_to :admin
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :groups, :through => :memberships, :order => 'groups.name'
  has_many :pictures, :order => 'created_at desc'
  has_many :messages
  has_many :wall_messages, :class_name => 'Message', :foreign_key => 'wall_id', :order => 'created_at desc'
  has_many :recipes, :order => 'title'
  has_many :notes, :order => 'created_at desc', :conditions => ['deleted = ?', false]
  has_many :updates, :order => 'created_at'
  has_many :pending_updates, :class_name => 'Update', :foreign_key => 'person_id', :order => 'created_at', :conditions => ['complete = ?', false]
  has_many :songs
  has_many :prayer_signups
  has_and_belongs_to_many :verses, :order => 'book, chapter, verse'
  has_many :log_items
  has_many :blog_items
  has_many :friendships, :order => 'ordering, created_at'
  has_many :friends, :class_name => 'Person', :through => :friendships, :order => 'friendships.ordering, friendships.created_at'
  has_many :friendship_requests
  has_many :pending_friendship_requests, :class_name => 'FriendshipRequest', :conditions => ['rejected = ?', false]
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :sync_instances
  has_many :remote_accounts
  has_many :attendance_records
  belongs_to :site

  has_many :services, :dependent => :destroy do
    def current
      self.find(:all, :conditions => {:status => 'current'}, :include => :service_category, :order => 'service_categories.name')
    end

    def pending
      self.find(:all, :conditions => {:status => 'pending'}, :include => :service_category, :order => 'service_categories.name')
    end

    def historical
      self.find(:all, :conditions => {:status => 'completed'}, :include => :service_category, :order => 'service_categories.name')
    end
  end
  has_many :service_categories, :through => :services
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
    
  acts_as_password
  acts_as_photo "#{DB_PHOTO_PATH}/people", PHOTO_SIZES
    
  acts_as_logger LogItem

  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :loggable_type => 'Person', :loggable_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  attr_protected :api_key, :feed_code

  validates_length_of :password, :minimum => 5, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_confirmation_of :password, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :alternate_email, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :feed_code, :allow_nil => true
  validates_format_of :website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/, :message => "has an incorrect format (are you missing 'http://' at the beginning?)"
  validates_format_of :business_website, :allow_nil => true, :allow_blank => true, :with => /^https?\:\/\/.+/, :message => "has an incorrect format (are you missing 'http://' at the beginning?)"
  validates_format_of :business_email, :allow_nil => true, :allow_blank => true, :with => VALID_EMAIL_ADDRESS, :message => 'has an incorrect format (something@example.com)'
  validates_presence_of :gender, :if => Proc.new { Person.logged_in }
  
  # validate that an email address is unique to one family (family members may share an email address)
  # validate that an email address is properly formatted
  validates_each :email, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any?
      if Person.count('*', :conditions => ["#{sql_lcase('email')} = ? and family_id != ? and id != ?", value.downcase, record.family_id, record.id]) > 0
        record.errors.add attribute, 'already taken by someone else.'
      end
      if value.to_s.strip !~ VALID_EMAIL_ADDRESS
        record.errors.add attribute, 'not a valid email address.'
      end
      if record.email_changed? and not Setting.get(:access, :super_admins).include?(record.email_was) and record.super_admin?
        record.errors.add attribute, 'is invalid.' # cannot make yourself a super admin
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
  
  def inspect
    "<#{name}>"
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
  
  def pretty_website
    website && website.sub(/^https?:\/\//, '')
  end
  
  def can_see?(*whats)
    whats.select do |what|
      case what.class.name
      when 'Person'
        !what.deleted? and (
          what == self or
          what.family_id == self.family_id or
          admin?(:view_hidden_profiles) or
          staff? or (
            what.visible_to_everyone? and
            what.visible? and (
              full_access? or
              what.adult?
            )
          )
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
    else
      raise "Unrecognized argument to can_edit? (#{what.inspect})"
    end
  end
  
  def can_sync_remotely?
    self.admin?(:view_hidden_properties)
  end
  
  def can_sign_in?
    read_attribute(:can_sign_in) and consent_or_13?
  end
  
  def full_access?
    read_attribute(:full_access) or admin? or staff? or elder? or deacon?
  end
  
  def member_of?(group)
    memberships.find_by_group_id(group.id)
  end
  
  def at_least?(age)
    today = Date.today
    back = Date.new(today.year-age, today.month, today.day) rescue Date.new(today.year-age, today.month, today.day-1)
    %w(male female man woman).include?(gender.downcase) or (birthday and birthday <= back)
  end
  
  def age
    birthday && birthday.distance_to(Date.today)
  end
  
  def years_of_age(on=Date.today)
    return nil unless birthday
    years = on.year - birthday.year
    years -= 1 if on.month < birthday.month
    years -= 1 if on.month == birthday.month and on.day < birthday.day
    years
  end
  
  def at_least_13?; at_least?(13); end
  def adult?; at_least?(18); end
  
  def parental_consent?; parental_consent.to_s.any?; end
  def consent_or_13?; at_least_13? or parental_consent?; end
  
  def visible?
    family and family.visible? and read_attribute(:visible) and (at_least_13? or parental_consent?) and visible_to_everyone?
  end

  def admin=(a)
    if a == true
      Admin.create(:person => self)
    elsif a == false
      self.admin.destroy rescue nil
    elsif a.is_a? Admin
      a.person = self
      a.save
    end
  end
  
  def admin?(perm=nil)
    (admin and (perm.nil? or admin.send(perm))) or super_admin?
  end
  
  def super_admin?
    Setting.get(:access, :super_admins).include?(email)
  end
  
  def valid_email?
    email.to_s.strip =~ VALID_EMAIL_ADDRESS
  end
  
  # legacy from old way of gathering blog_items TODO: remove this
  def blog_items_count
    blog_items.count('*')
  end
  
  # get the parents/guardians by grabbing people in family sequence 1 and 2 and with gender male or female
  def parents
    if family 
      family.people.select { |p| p.adult? and [1, 2].include? p.sequence }
    end
  end
  
  def active?
    log_items.count(["created_at >= ?", 1.day.ago]) > 0
  end
  
  def has_shares?
    @has_shares ||= verses.count > 0 or recipes.count > 0 or pictures.count > 0
  end
  
  def has_notes?
    @has_notes ||= notes.count > 0
  end
  
  def has_groups?
    @has_groups ||= groups.count > 0
  end

  def has_services?
    @has_services ||= services.count > 0
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
  
  def update_from_params(params)
    if params[:photo_url] and params[:photo_url].length > 7 # not just "http://"
      self.photo = params[:photo_url]
      'photo'
    elsif params[:photo]
      self.photo = params[:photo] == 'remove' ? nil : params[:photo]
      'photo'
    elsif params[:person] and (BASICS.detect { |a| params[:person][a] } or params[:family])
      self.email = params[:person].delete(:email) # no 'update' necessary
      self.save if email_changed?
      if Person.logged_in.admin?(:edit_profiles) or not Setting.get(:features, :updates_must_be_approved)
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
      if params[:person][:twitter_account].to_s.strip.any? and params[:person][:twitter_account] != self.twitter_account
        TwitterBot.follow(params[:person][:twitter_account]) rescue nil
      end
      update_attributes params[:person].reject { |k, v| !EXTRAS.include?(k) }
    else
      self
    end
  end
  
  def suffix=(s)
    s = nil if s.blank?
    write_attribute(:suffix, s)
  end
  
  before_update :mark_email_changed
  def mark_email_changed
    if changed.include?('email') and not Person.sync_in_progress
      self.write_attribute(:email_changed, true)
      if Person.logged_in and not Person.logged_in.admin?
        Notifier.deliver_email_update(self)
      end
    end
  end
  
  def recently_tab_items
    friend_ids = [id]
    friend_ids += friends.find(:all, :select => 'people.id').map { |f| f.id } if Setting.get(:features, :friends)
    group_ids = groups.select { |g| !g.hidden? }.map { |g| g.id }
    group_ids = [0] unless group_ids.any?
    LogItem.find(
      :all,
      :conditions => ["((log_items.loggable_type in ('Friendship', 'Picture', 'Verse', 'Recipe', 'Person', 'Message', 'Note', 'Comment') and log_items.person_id in (#{friend_ids.join(',')})) or (log_items.loggable_type in ('Note', 'Message', 'PrayerRequest') and log_items.group_id in (#{group_ids.join(',')}))) and log_items.deleted = ? and (people.share_activity = ? or (people.share_activity is null and (select share_activity from families where id=people.family_id limit 1) = ?))", false, true, true],
      :order => 'log_items.created_at desc',
      :limit => 25,
      :select => "log_items.*, people.family_id, people.share_activity",
      :joins => :person
    ).select do |item|
      if !(obj = item.object)
        false
      elsif item.loggable_type == 'Verse' # habtm
        true
      elsif !(p_id = obj.is_a?(Person) ? obj.id : obj.person_id) or p_id != item.person_id # in case an admin does something
        false
      elsif obj.respond_to?(:deleted?) and obj.deleted?
        false
      elsif item.loggable_type == 'Person' # made some profile adjustments
        obj == self and item.showable_change_keys.any?
      elsif item.loggable_type == 'Friendship'
        obj.person_id != item.person_id
      elsif item.loggable_type == 'Message'
        obj.can_see?(self) and not obj.to
      else
        true
      end
    end
  end
  
  alias_method :destroy_for_real, :destroy
  def destroy
    self.update_attributes!(:deleted => true)
  end
  
  def self.business_categories
    find_by_sql("select distinct business_category from people where business_category is not null and business_category != '' order by business_category").map { |p| p.business_category }
  end  

  # model extensions
  Dir[Rails.root + '/app/models/person/*.rb'].each do |ext|
    load(ext)
    mod_name = ext.split('/').last.split('.').first.classify
    class_eval "include Person::#{mod_name}"
  end

end
