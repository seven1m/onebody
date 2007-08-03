# == Schema Information
# Schema version: 74
#
# Table name: people
#
#  id                           :integer(11)   not null, primary key
#  legacy_id                    :integer(11)   
#  family_id                    :integer(11)   
#  sequence                     :integer(11)   
#  gender                       :string(6)     
#  first_name                   :string(255)   
#  last_name                    :string(255)   
#  suffix                       :string(25)    
#  mobile_phone                 :integer(20)   
#  work_phone                   :integer(20)   
#  fax                          :integer(20)   
#  birthday                     :datetime      
#  email                        :string(255)   
#  email_changed                :boolean(1)    
#  website                      :string(255)   
#  classes                      :string(255)   
#  shepherd                     :string(255)   
#  mail_group                   :string(1)     
#  encrypted_password           :string(100)   
#  service_name                 :string(100)   
#  service_description          :text          
#  service_phone                :integer(20)   
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
#  share_mobile_phone           :boolean(1)    
#  share_work_phone             :boolean(1)    
#  share_fax                    :boolean(1)    
#  share_email                  :boolean(1)    
#  share_birthday               :boolean(1)    
#  anniversary                  :datetime      
#  updated_at                   :datetime      
#  alternate_email              :string(255)   
#  email_bounces                :integer(11)   default(0)
#  service_category             :string(100)   
#  get_wall_email               :boolean(1)    default(TRUE)
#  frozen                       :boolean(1)    
#  wall_enabled                 :boolean(1)    
#  messages_enabled             :boolean(1)    default(TRUE)
#  service_address              :string(255)   
#  flags                        :string(255)   
#  music_access                 :boolean(1)    
#  visible                      :boolean(1)    default(TRUE)
#  parental_consent             :string(255)   
#  admin_id                     :integer(11)   
#  friends_enabled              :boolean(1)    default(TRUE)
#  member                       :boolean(1)    
#  staff                        :boolean(1)    
#  elder                        :boolean(1)    
#  deacon                       :boolean(1)    
#  can_sign_in                  :boolean(1)    
#  visible_to_everyone          :boolean(1)    
#  visible_on_printed_directory :boolean(1)    
#  full_access                  :boolean(1)    
#  legacy_family_id             :integer(11)   
#

class Person < ActiveRecord::Base
  cattr_accessor :logged_in # set in addition to @logged_in (for use by Notifier and other models)
  
  belongs_to :family
  belongs_to :admin
  has_many :memberships
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
    
  acts_as_password
  acts_as_photo '/db/photos/people', PHOTO_SIZES
    
  acts_as_logger LogItem

  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :model_name => 'Person', :instance_id => id, :changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  validates_length_of :password, :minimum => 5, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_confirmation_of :password, :if => Proc.new { Person.logged_in }
  validates_uniqueness_of :alternate_email, :allow_nil => true, :if => Proc.new { Person.logged_in }
  validates_format_of :website, :allow_nil => true, :with => /^https?\:\/\/.+/, :if => Proc.new { Person.logged_in }
  
  # validate that an email address is unique to one family (family members may share an email address)
  # validate that an email address is properly formatted
  validates_each :email, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any?
      if Person.count('*', :conditions => ['LCASE(email) = ? and family_id != ?', value.downcase, record.family_id]) > 0
        record.errors.add attribute, 'already taken by someone else.'
      end
      if value.to_s.strip !~ VALID_EMAIL_RE
        record.errors.add attribute, 'not a valid email address.'
      end
    end
  end
  
  # This method is used all over the site to show the person's name.
  # Since this method and the person's profile are the only places a child's personal information
  #   could be displayed, we'll check that the person currently logged in can see this name.
  # To do this for every attribute would generate too much overhead.
  def name
    @name ||= begin
      if Person.logged_in.nil? or Person.logged_in.can_see? self
        if suffix
          "#{first_name} #{last_name}, #{suffix}" rescue '???'
        else
          "#{first_name} #{last_name}" rescue '???'
        end
      else
        '???'
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
  
  inherited_attribute :share_mobile_phone, :family
  inherited_attribute :share_work_phone, :family
  inherited_attribute :share_fax, :family
  inherited_attribute :share_email, :family
  inherited_attribute :share_birthday, :family
  inherited_attribute :wall_enabled, :family
  def share_address; family.share_address; end
  def share_anniversary; family.share_anniversary; end
  
  share_with :mobile_phone
  share_with :work_phone
  share_with :fax
  share_with :email
  share_with :birthday
  share_with :address
  share_with :anniversary
  
  def groups_sharing(attribute)
    memberships.find(:all, :conditions => ["share_#{attribute.to_s} = ?", true]).map { |m| m.group }
  end
  
  def home_phone; family.home_phone; end
  def address1; family.address1; end
  def address2; family.address2; end
  def city; family.city; end
  def state; family.state; end
  def zip; family.zip; end
  
  def can_see?(what)
    if what.is_a? Person
      what == self or
      what.family_id == self.family_id or
      admin?(:view_hidden_profiles) or
      staff? or 
      (what.visible_to_everyone? and (full_access? or what.adult?) and what.visible?)
    elsif what.is_a? Group
      not what.hidden? or what.people.include? self or what.admin? self
    elsif what.is_a? Message
      if what.group
        not what.group.private? or what.group.people.include?(self)
      else
        admin?(:manage_messages) or what.to == self or what.wall == self or what.person == self
      end
    else
      raise 'unknown "what"'
    end
  end
  
  alias_method :sees?, :can_see?
  
  def can_edit?(what)
    if what.is_a? Group
      what.admin? self or self.admin?(:manage_groups)
    elsif what.is_a? Ministry
      admin?(:manage_ministries) or what.administrator == self
    elsif what.is_a? Person
      admin?(:edit_profiles) or (what.family == self.family and self.adult?) or what == self
    elsif what.is_a? Family
      admin?(:edit_profiles) or (what == self.family and self.adult?)
    elsif what.is_a? Message
      admin?(:manage_messages) or what.person == self or (what.group and what.group.admin? self)
    else
      raise 'unknown "what"'
    end
  end
  
  def can_sign_in?
    read_attribute(:can_sign_in) and consent_or_13?
  end
  
  def full_access?
    read_attribute(:full_access) or admin? or staff? or elder? or deacon?
  end
  
  def at_least?(age)
    today = Date.today
    %w(male female man woman).include?(gender.downcase) or (birthday and birthday <= Date.new(today.year-age, today.month, today.day))
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
    family.visible? and read_attribute(:visible) and (at_least_13? or parental_consent?) and visible_to_everyone?
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
    email.to_s.strip =~ VALID_EMAIL_RE
  end
  
  def blog_items_count
    pictures.count + verses.count + recipes.count + notes.count
  end
  
  def blog_items
    log_items.find(
      :all,
      :order => 'created_at desc',
      :conditions => "model_name in ('Verse', 'Recipe', 'Note', 'Picture')",
      :limit => 25
    ).map { |item| item.object }
  end
  
  alias_method :groups_without_linkage, :groups
  
  def groups
    if @groups.nil?
      g = groups_without_linkage
      conditions = []
      classes.to_s.split(',').each do |code|
        conditions.add_condition ['LCASE(link_code) = ? or link_code like ? or link_code like ? or link_code like ?', code.downcase, "#{code} %", "% #{code}", "% #{code} %"], 'or'
      end
      g = (g + Group.find(:all, :conditions => conditions)).uniq if conditions.any?
      @groups = g
    end
    @groups
  end
  
  # get the parents/guardians by grabbing people in family sequence 1 and 2 and with gender male or female
  def parents
    family.people.select { |p| p.adult? and [1, 2].include? p.sequence }
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
end
