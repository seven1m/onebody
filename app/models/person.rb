class Person < ActiveRecord::Base  
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
  has_and_belongs_to_many :verses
  
  acts_as_password
  acts_as_photo '/db/photos/people', PHOTO_SIZES
  
  #validates_presence_of :email
  validates_length_of :password, :minimum => 5, :allow_nil => true
  validates_confirmation_of :password
  
  validates_each :email, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'email'
      if Person.count(:conditions => ['LCASE(email) = ? and family_id != ?', value.downcase, record.family_id]) > 0
        record.errors.add attribute, 'already taken by someone else.'
      end
      if value !~ /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
        record.errors.add attribute, 'not a valid email address.'
      end
    end
  end
  
  def name
    if suffix
      "#{first_name} #{last_name}, #{suffix}" rescue '???'
    else
      "#{first_name} #{last_name}" rescue '???'
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
      admin? or
      (
        MAIL_GROUPS_VISIBLE_BY_NON_ADMINS.include? what.mail_group \
        and
        (member? or what.adult?)
      )
    elsif what.is_a? Group
      not what.private? or what.people.include? self or what.admin? self
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
      what.family == self.family and self.adult?
    else
      raise 'unknown "what"'
    end
  end
  
  def adult?
    today = Date.today
    %w(male female man woman).include?(gender.downcase) or (birthday and birthday <= Date.new(today.year-18, today.month, today.day))
  end
  
  def member?
    %w(M A).include? mail_group
  end
  
  def admin?
    @admin ||= ADMIN_CHECK.call(self)
  end
  
  def mapable?
    family.mapable?
  end
  
  alias_method :groups_without_linkage, :groups
  
  def groups
    g = groups_without_linkage
    classes.split(',').each do |code|
      g << Group.find(:all, :conditions => ['LCASE(link_code) = ? or link_code like ? or link_code like ? or link_code like ?', code.downcase, "#{code} %", "% #{code}", "% #{code} %"])
    end
    g.flatten.uniq
  end
   
end
