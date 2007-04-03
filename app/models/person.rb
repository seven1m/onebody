class Person < ActiveRecord::Base
  cattr_accessor :logged_in
  
  belongs_to :family
  has_many :memberships
  has_many :groups, :through => :memberships, :order => 'groups.name', :conditions => ["groups.subscription = ? and (groups.link_code is null or groups.link_code = '')", false]
  has_many :contacts, :foreign_key => 'owner_id'
  has_many :people, :through => :contacts, :order => 'people.last_name, people.first_name'
  has_many :pictures, :order => 'created_at desc'
  has_many :messages
  has_many :wall_messages, :class_name => 'Message', :foreign_key => 'wall_id', :order => 'created_at desc'
  has_many :recipes, :order => 'title'
  has_many :updates, :order => 'created_at'
  has_many :pending_updates, :class_name => 'Update', :foreign_key => 'person_id', :order => 'created_at', :conditions => ['complete = ?', false]
  has_many :songs
  has_many :prayer_signups
  has_and_belongs_to_many :verses
  has_many :log_items
  
  acts_as_password
  acts_as_photo '/db/photos/people', PHOTO_SIZES
  
  acts_as_logger LogItem

  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :model_name => 'Person', :instance_id => id, :changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  #validates_presence_of :email
  validates_length_of :password, :minimum => 5, :allow_nil => true
  validates_confirmation_of :password
  validates_uniqueness_of :alternate_email, :allow_nil => true
  
  validates_each :email, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'email' and value.to_s.any?
      if Person.count(:conditions => ['LCASE(email) = ? and family_id != ?', value.downcase, record.family_id]) > 0
        record.errors.add attribute, 'already taken by someone else.'
      end
      if value !~ /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
        record.errors.add attribute, 'not a valid email address.'
      end
    end
  end

  before_save :cleanup_website
  def cleanup_website
    self.website = "http://#{website}" if website.to_s.any? and website !~ /^http:\/\//
  end
  
  def name
    if suffix
      "#{first_name} #{last_name}, #{suffix}" rescue '???'
    else
      "#{first_name} #{last_name}" rescue '???'
    end
  end

  def first_name
    if p = NAME_CONVERSIONS[:people][id] and n = p[:first_name]
      n
    else
      read_attribute(:first_name)
    end
  end

  def last_name
    if p = NAME_CONVERSIONS[:people][id] and n = p[:last_name]
      n
    else
      read_attribute(:last_name)
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
      admin? or
      (
        (MAIL_GROUPS_VISIBLE_BY_NON_ADMINS.include? what.mail_group or what.flags.to_s.include? FLAG_VISIBLE_BY_NON_ADMINS) \
        and
        (member? or what.adult?) \
        and
        what.visible?
      )
    elsif what.is_a? Group
      not what.private? or what.people.include? self or what.admin? self
    elsif what.is_a? Message
      if what.group
        can_see? what.group
      else
        admin? or what.to == self or what.wall == self or what.person == self
      end
    else
      raise 'unknown "what"'
    end
  end
  
  alias_method :sees?, :can_see?
  
  def can_edit?(what)
    if what.is_a? Group
      what.admin? self
    elsif what.is_a? Ministry
      admin? or what.administrator == self
    elsif what.is_a? Person
      admin? or (what.family == self.family and self.adult?) or what == self
    elsif what.is_a? Family
      admin? or (what == self.family and self.adult?)
    elsif what.is_a? Message
      admin? or what.person == self or (what.group and what.group.admin? self)
    else
      raise 'unknown "what"'
    end
  end
  
  def member?
    %w(M A C).include? mail_group
  end
  
  def at_least?(age)
    today = Date.today
    %w(male female man woman).include?(gender.downcase) or (birthday and birthday <= Date.new(today.year-age, today.month, today.day))
  end
  
  def at_least_13?; at_least?(13); end
  def adult?; at_least?(18); end
  
  def can_sign_in?
    MAIL_GROUPS_CAN_LOG_IN.include? mail_group and consent_or_13?
  end
  
  def parental_consent?; not parental_consent_at.nil?; end
  def consent_or_13?; at_least_13? or parental_consent?; end
  
  def visible?
    family.visible? and read_attribute(:visible) and (at_least_13? or parental_consent?)
  end

  def church_member?
    mail_group == 'M'
  end
  
  def admin?
    if @admin.nil?
      @admin = ADMIN_CHECK.call(self) ? true : false
    end
    @admin
  end
  
  def mapable?
    family.mapable?
  end
  
  alias_method :groups_without_linkage, :groups
  
  def groups
    if @groups.nil?
      g = groups_without_linkage
      conditions = []
      classes.split(',').each do |code|
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
end
