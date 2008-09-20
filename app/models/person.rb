# == Schema Information
#
# Table name: people
#
#  id                           :integer       not null, primary key
#  legacy_id                    :integer       
#  family_id                    :integer       
#  sequence                     :integer       
#  gender                       :string(6)     
#  first_name                   :string(255)   
#  last_name                    :string(255)   
#  suffix                       :string(25)    
#  mobile_phone                 :integer       
#  work_phone                   :integer       
#  fax                          :integer       
#  birthday                     :datetime      
#  email                        :string(255)   
#  email_changed                :boolean       
#  website                      :string(255)   
#  classes                      :string(255)   
#  shepherd                     :string(255)   
#  mail_group                   :string(1)     
#  encrypted_password           :string(100)   
#  service_name                 :string(100)   
#  service_description          :text          
#  service_phone                :integer       
#  service_email                :string(255)   
#  service_website              :string(255)   
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
#  anniversary                  :datetime      
#  updated_at                   :datetime      
#  alternate_email              :string(255)   
#  email_bounces                :integer       default(0)
#  service_category             :string(100)   
#  get_wall_email               :boolean       default(TRUE)
#  account_frozen               :boolean       
#  wall_enabled                 :boolean       
#  messages_enabled             :boolean       default(TRUE)
#  service_address              :string(255)   
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
#  twitter_account              :string(100)   
#  api_key                      :string(50)    
#  salt                         :string(50)    
#

class Person < ActiveRecord::Base

  cattr_accessor :logged_in # set in addition to @logged_in (for use by Notifier and other models)
  
  belongs_to :family
  belongs_to :admin
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :groups, :through => :memberships, :order => 'groups.name', :conditions => "groups.link_code is null or groups.link_code = ''"
  has_many :contacts, :foreign_key => 'owner_id'
  has_many :people, :through => :contacts, :order => 'people.last_name, people.first_name'
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
  has_many :friendships, :order => 'ordering, created_at'
  has_many :friends, :class_name => 'Person', :through => :friendships, :order => 'friendships.ordering, friendships.created_at'
  has_many :friendship_requests
  has_many :pending_friendship_requests, :class_name => 'FriendshipRequest', :conditions => ['rejected = ?', false]
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :sync_instances
  has_many :remote_accounts
  has_many :attendance_records
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
    
  acts_as_password
  acts_as_photo "#{DB_PHOTO_PATH}/people", PHOTO_SIZES
    
  acts_as_logger LogItem

  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :model_name => 'Person', :instance_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  attr_protected :api_key, :feed_code

  validates_length_of :password, :minimum => 5, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_confirmation_of :password, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :alternate_email, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :feed_code, :allow_nil => true
  validates_format_of :website, :allow_nil => true, :with => /^https?\:\/\/.+/, :if => :validate_website  
  validates_format_of :service_website, :allow_nil => true, :with => /^https?\:\/\/.+/, :if => :validate_service_website, :message => " has an incorrect format (are you missing 'http://' at the beginning?)"
  validates_format_of :service_email, :allow_nil => true, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :message => ' has an incorrect format (something@example.com)'
  validates_presence_of :gender, :if => Proc.new { Person.logged_in }

  def validate_website
    Person.logged_in and website.to_s.strip.any?
  end
  
  def validate_service_website
    Person.logged_in and service_website.to_s.strip.any?
  end
  
  # validate that an email address is unique to one family (family members may share an email address)
  # validate that an email address is properly formatted
  validates_each :email, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any?
      if Person.count('*', :conditions => ["#{sql_lcase('email')} = ? and family_id != ?", value.downcase, record.family_id]) > 0
        record.errors.add attribute, 'already taken by someone else.'
      end
      if value.to_s.strip !~ VALID_EMAIL_ADDRESS
        record.errors.add attribute, 'not a valid email address.'
      end
    end
  end
  
  def name
    @name ||= begin
      if suffix
        "#{first_name} #{last_name}, #{suffix}" rescue '???'
      else
        "#{first_name} #{last_name}" rescue '???'
      end
    end
  end

  def name_shortened(max)
    if name and name.length > max
      name[0..max-3] + '...'
    else
      name
    end
  end
  
  def name_possessive
    n = name
    n =~ /s$/ ? "#{n}'" : "#{n}'s"
  end
  
  def inspect
    "<#{name}>"
  end
  
  def birthday_soon?
    today = Date.today
    birthday and birthday >= today and birthday < (today + BIRTHDAY_SOON_DAYS)
  end
  
  def mobile_phone=(phone)
    write_attribute :mobile_phone, phone.to_s.digits_only
  end
  
  def work_phone=(phone)
    write_attribute :work_phone, phone.to_s.digits_only
  end
  
  def fax=(phone)
    write_attribute :fax, phone.to_s.digits_only
  end
  
  before_create :generate_salt
  
  def generate_salt
    self.salt = random_chars(50) unless read_attribute(:salt)
  end
  
  def salt
    read_attribute(:salt) || generate_salt
  end
  
  inherited_attribute :share_mobile_phone, :family
  inherited_attribute :share_work_phone, :family
  inherited_attribute :share_fax, :family
  inherited_attribute :share_email, :family
  inherited_attribute :share_birthday, :family
  inherited_attribute :share_activity, :family
  inherited_attribute :wall_enabled, :family
  def share_home_phone ; family.share_home_phone ; end
  def share_address    ; family.share_address    ; end
  def share_anniversary; family.share_anniversary; end

  share_with :home_phone  
  share_with :mobile_phone
  share_with :work_phone
  share_with :fax
  share_with :email
  share_with :birthday
  share_with :address
  share_with :anniversary
  share_with :activity
  
  def groups_sharing(attribute)
    memberships.find(:all, :conditions => ["share_#{attribute.to_s} = ?", true]).map { |m| m.group }
  end
  
  def home_phone; family.home_phone; end
  def address; family.address; end
  def address1; family.address1; end
  def address2; family.address2; end
  def city; family.city; end
  def state; family.state; end
  def zip; family.zip; end
  
  def can_see?(*whats)
    whats.select do |what|
      case what.class.name
      when 'Person'
        what == self or
        what.family_id == self.family_id or
        admin?(:view_hidden_profiles) or
        staff? or 
        (what.visible_to_everyone? and (full_access? or what.adult?) and what.visible?)
      when 'Family'
        what.visible? or admin?(:view_hidden_profiles)
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
      admin?(:edit_profiles) or (what.family == self.family and self.adult?) or what == self
    when 'Family'
      admin?(:edit_profiles) or (what == self.family and self.adult?)
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
    return true if self.memberships.count('*', :conditions => ['group_id = ?', group.id]) > 0
    if group.parents_of
      group.cached_parents.to_a.include?(self.id)
    elsif group.linked?
      codes = self.classes.to_s.downcase.split(',')
      group.link_code.downcase.split.each do |code|
        return true if codes.include? code
      end
    end
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
    @super_admin ||= SUPER_ADMIN_CHECK.call(self)
  end
  
  def mapable?
    family.mapable?
  end
  
  def request_friendship_with(person)
    if person.friendship_waiting_on?(self)
      # already requested by other person
      self.friendships.create! :friend => person
      self.friendship_requests.find_by_from_id(person.id).destroy
      "#{person.name} has been added as a friend."
    elsif self.can_request_friendship_with?(person)
      # clean up past rejections
      FriendshipRequest.delete_all ['person_id = ? and from_id = ? and rejected = ?', self.id, person.id, true]
      person.friendship_requests.create!(:from => self)
      "A friend request has been sent to #{person.name}."
    elsif self.friendship_waiting_on?(person)
      "A friend request is already pending with #{person.name}."
    elsif self.friendship_rejected_by?(person)
      "You cannot request friendship with #{person.name}."
    else
      raise 'unknown state'
    end
  end
  
  def can_request_friendship_with?(person)
    person != self and !friend?(person) and full_access? and person.full_access? and person.valid_email? and person.friends_enabled and !friendship_rejected_by?(person) and !friendship_waiting_on?(person)
  end
  
  def friendship_rejected_by?(person)
    person.friendship_requests.count('*', :conditions => ['from_id = ? and rejected = ?', self.id, true]) > 0
  end
  
  def friendship_waiting_on?(person)
    person.friendship_requests.count('*', :conditions => ['from_id = ? and rejected = ?', self.id, false]) > 0
  end
  
  def friend?(person)
    friends.count('*', :conditions => ['friend_id = ?', person.id]) > 0
  end
  
  def valid_email?
    email.to_s.strip =~ VALID_EMAIL_ADDRESS
  end
  
  def blog_items_count
    pictures.count + verses.count + recipes.count + notes.count
  end
  
  def blog_items
    classes = %w(Verse Recipe Note Picture).select { |c| Setting.get(:features, c.downcase.pluralize.to_sym) }
    classes.map! { |c| "'" + c + "'" }
    log_items.find(
      :all,
      :order => 'created_at desc',
      :conditions => "model_name in (#{classes.join(',')})",
      :limit => 25
    ).map { |item| item.object }.select { |o| o and (o.respond_to?(:person_id) ? o.person_id == self.id : o.people.include?(self)) and not (o.respond_to?(:deleted?) and o.deleted?) }
  end
  
  alias_method :groups_without_linkage, :groups
  
  def groups
    if @groups.nil?
      g = groups_without_linkage
      conditions = []
      classes.to_s.split(',').each do |code|
        conditions.add_condition ["#{sql_lcase('link_code')} = ? or link_code like ? or link_code like ? or link_code like ?", code.downcase, "#{code} %", "% #{code}", "% #{code} %"], 'or'
      end
      g = (g + Group.find(:all, :conditions => conditions)).uniq if conditions.any?
      @groups = g
    end
    @groups
  end
  
  def sidebar_groups
    Setting.get(:features, :sidebar_group_category) && \
      groups.select { |g| g.category.to_s.downcase == Setting.get(:features, :sidebar_group_category).downcase }
  end
  
  def sidebar_group_people
    @sidebar_group_people ||= begin
      sidebar_groups.map { |g| g.people }.flatten.uniq.delete_if { |p| p == self }.sort_by(&:name)
    end
  end
  
  # get the parents/guardians by grabbing people in family sequence 1 and 2 and with gender male or female
  def parents
    if family 
      family.people.select { |p| p.adult? and [1, 2].include? p.sequence }
    end
  end
  
  def parent_mobile_phones(formatted=false)
    parents.map { |p| number_to_phone(p.mobile_phone, :area_code => true) }.select { |p| p.any? }
  end

  def active?
    log_items.count(["created_at >= ?", 1.day.ago]) > 0
  end
  
  def has_shares?
    @has_shares ||= verses.any? or recipes.any? or pictures.any?
  end
  
  def has_notes?
    @has_notes ||= notes.count > 0
  end
  
  def has_groups?
    @has_groups ||= groups.any?
  end
  
  def access_attributes
    self.attributes.keys.grep(/_access$/).reject { |a| a == 'full_access' }
  end
  
  # generates security code for grabbing feed(s) without logging in
  before_create :update_feed_code
  def update_feed_code
    begin # ensure unique
      code = random_chars(50)
      write_attribute :feed_code, code
    end while Person.count('*', :conditions => ['feed_code = ?', code]) > 0
  end
  
  def generate_api_key
    write_attribute :api_key, random_chars(50)
  end
  
  def update_from_params(params)
    person_basics = %w(first_name last_name suffix mobile_phone work_phone fax city state zip birthday anniversary gender address1 address2 city state zip)
    if params[:photo_url] and params[:photo_url].length > 7 # not just "http://"
      self.photo = params[:photo_url]
      'photo'
    elsif params[:photo]
      self.photo = params[:photo] == 'remove' ? nil : params[:photo]
      'photo'
    elsif params[:person] and (person_basics.detect { |a| params[:person][a] } or params[:family])
      if Person.logged_in.admin?(:edit_profiles)
        params[:family] ||= {}
        params[:family][:legacy_id] = params[:person][:legacy_family_id] if params[:person][:legacy_family_id]
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
      params[:person][:service_phone] = params[:person][:service_phone].digits_only if params[:person][:service_phone]
      if params[:person][:twitter_account].to_s.strip.any? and params[:person][:twitter_account] != self.twitter_account
        TwitterBot.follow(params[:person][:twitter_account]) rescue nil
      end
      update_attributes params[:person]
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
    if changed.include?('email') and Person.logged_in
      self.write_attribute(:email_changed, true)
      Notifier.deliver_email_update(self)
    end
  end
  
  class << self # Import data methods
  
    def queue_import_from_csv_file(file, match_by_name=true)
      data = CSV.parse(file)
      attributes = data.shift
      data.map do |row|
        person, family = get_changes_for_import(attributes, row, match_by_name)
        if person.changed? or family.changed?
          changes = person.changes.clone
          family.changes.each { |k, v| changes['family_' + k] = v }
          [person, changes]
        else
          nil
        end
      end.compact
    end
    
    def get_changes_for_import(attributes, row, match_by_name=true)
      row_as_hash = {}
      row.each_with_index do |col, index|
        row_as_hash[attributes[index]] = col
      end
      person_hash, family_hash = split_change_hash(row_as_hash)
      if record = tiered_find(person_hash, match_by_name)
        record.attributes = person_hash
        record.family.attributes = family_hash
        [record, record.family]
      else
        [new(person_hash), Family.new(family_hash)]
      end
    end
    
    def tiered_find(attributes, match_by_name=true)
      a = attributes.clone.reject_blanks
      a['id']        &&
        find_by_id(a['id'])               ||
      a['legacy_id'] &&
        find_by_legacy_id(a['legacy_id']) ||
      match_by_name  && a['first_name'] && a['last_name'] && a['birthday'] &&
        find_by_first_name_and_last_name_and_birthday(a['first_name'], a['last_name'], Date.parse(a['birthday'])) ||
      match_by_name  && a['first_name'] && a['last_name'] &&
        find_by_first_name_and_last_name(a['first_name'], a['last_name'])
    end
    
    def import_data(params)
      Person.transaction do
        params[:new].to_a.each do |key, vals|
          person_vals, family_vals = split_change_hash(vals)
          name = "#{person_vals['first_name']} #{person_vals['last_name']}"
          last_name = person_vals['last_name']
          family = Family.create!({:name => name, :last_name => last_name}.merge(family_vals))
          person = Person.create!(person_vals.merge(:family_id => family.id))
        end
        params[:changes].to_a.each do |id, vals|
          vals.cleanse(:birthday, :anniversary)
          person_vals, family_vals = split_change_hash(vals)
          person = Person.find(id)
          person.update_attributes!(person_vals)
          person.family.update_attributes!(family_vals)
        end
      end
    end

    def split_change_hash(vals)
      person_vals = {}
      family_vals = {}
      vals.each do |key, val|
        if key =~ /^family_/
          family_vals[key.sub(/^family_/, '')] = val
        else
          person_vals[key] = val
        end
      end
      person_vals.reject! { |k, v| !Person.column_names.include?(k) or k =~ /^share_|_at$|wall_enabled/ }
      family_vals.reject! { |k, v| !Family.column_names.include?(k) or k =~ /^share_|_at$|wall_enabled/ }
      [person_vals, family_vals]
    end
  
  end
  
  def recently_tab_items
    friend_ids = [id]
    friend_ids += friends.find(:all, :select => 'people.id').map { |f| f.id } if Setting.get(:features, :friends)
    group_ids = groups.select { |g| !g.hidden? }.map { |g| g.id }
    group_ids = [0] unless group_ids.any?
    LogItem.find(
      :all,
      :conditions => ["((log_items.model_name in ('Friendship', 'Picture', 'Verse', 'Recipe', 'Person', 'Message', 'Note', 'Comment') and log_items.person_id in (#{friend_ids.join(',')})) or (log_items.model_name in ('Note', 'Message', 'PrayerRequest') and log_items.group_id in (#{group_ids.join(',')}))) and log_items.deleted = ? and (people.share_activity = ? or (people.share_activity is null and (select share_activity from families where id=people.family_id limit 1) = ?))", false, true, true],
      :order => 'log_items.created_at desc',
      :limit => 25,
      :select => "log_items.*, people.family_id, people.share_activity",
      :joins => :person
    ).select do |item|
      if !(obj = item.object)
        false
      elsif item.model_name == 'Verse' # habtm
        true
      elsif !(p_id = obj.is_a?(Person) ? obj.id : obj.person_id) or p_id != item.person_id # in case an admin does something
        false
      elsif obj.respond_to?(:deleted?) and obj.deleted?
        false
      elsif item.model_name == 'Person' # made some profile adjustments
        obj == self and item.showable_change_keys.any?
      elsif item.model_name == 'Friendship'
        obj.person_id != item.person_id
      elsif item.model_name == 'Message'
        obj.can_see?(self) and not obj.to
      else
        true
      end
    end
  end
  
  def self.service_categories
    find_by_sql("select distinct service_category from people where service_category is not null and service_category != '' order by service_category").map { |p| p.service_category }
  end
  
  include ActionView::Helpers::NumberHelper # number_to_phone used by pdf generation below
  
  def generate_directory_pdf
    pdf = PDF::Writer.new
    pdf.margins_pt 70, 20, 20, 20
    pdf.open_object do |heading|
      pdf.save_state
      pdf.stroke_color! Color::RGB::Black
      pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT
      
      size = 24

      x = pdf.absolute_left_margin
      y = pdf.absolute_top_margin + 30
      pdf.add_text x, y, "#{Setting.get(:name, :church)} Directory\n\n", size

      x = pdf.absolute_left_margin
      w = pdf.absolute_right_margin
      #y -= (pdf.font_height(size) * 1.01)
      y -= 10
      pdf.line(x, y, w, y).stroke

      pdf.restore_state
      pdf.close_object
      pdf.add_object(heading, :all_following_pages)
    end

    s = 24
    w = pdf.text_width('Directory', s)
    x = pdf.margin_x_middle - w/2 # centered
    y = pdf.margin_y_middle - pdf.margin_height/4 # below center
    pdf.add_text x, y, 'Directory', s
    
    if Setting.get(:appearance, :logo).to_s.any?
      logo_path = "#{Rails.root}/public/images/#{Setting.get(:appearance, :logo)}"
      if File.exist?(logo_path) and img = MiniMagick::Image.from_blob(File.read(logo_path)) rescue nil
        pdf.add_image img.to_blob, pdf.margin_x_middle - img['width']/2, pdf.absolute_top_margin - 200
      end
    end
    
    t = "Created especially for #{self.name} on #{Date.today.strftime '%B %e, %Y'}"
    s = 14
    w = pdf.text_width(t, s)
    x = pdf.margin_x_middle - w/2 # centered
    y = pdf.margin_y_middle - pdf.margin_height/3 # below center
    pdf.add_text x, y, t, s
    
    pdf.start_new_page
    pdf.start_columns
    
    alpha = nil
    
    Family.find(
      :all,
      :conditions => ["(select count(*) from people where family_id = families.id and visible_on_printed_directory = ?) > 0", true],
      :order => 'families.last_name, families.name, people.sequence',
      :include => 'people'
    ).each do |family|
      if family.mapable? or family.home_phone.to_i > 0
        pdf.move_pointer 120 if pdf.y < 120
        if family.last_name[0..0] != alpha
          pdf.move_pointer 150 if pdf.y < 150
          alpha = family.last_name[0..0]
          pdf.text alpha + "\n", :font_size => 25
          pdf.line(
            pdf.absolute_left_margin,
            pdf.y - 5,
            pdf.absolute_left_margin + pdf.column_width - 25,
            pdf.y - 5
          ).stroke
          pdf.move_pointer 10
        end
        pdf.text family.name + "\n", :font_size => 18
        if family.people.length > 2
          p = family.people.map do |p|
            p.last_name == family.last_name ? p.first_name : p.name
          end.join(', ')
          pdf.text p + "\n", :font_size => 11
        end
        if family.share_address_with(self) and family.mapable?
          pdf.text family.address1 + "\n", :font_size => 14
          pdf.text family.address2 + "\n" if family.address2.to_s.any?
          pdf.text family.city + ', ' + family.state + '  ' + family.zip + "\n"
        end
        pdf.text number_to_phone(family.home_phone, :area_code => true), :font_size => 14 if family.home_phone.to_i > 0
        pdf.text "\n"
      end
    end
    
    pdf
  end
  
  def generate_directory_pdf_to_file(filename)
    File.open(filename, 'wb') { |f| f.write(generate_directory_pdf) }
  end

end

