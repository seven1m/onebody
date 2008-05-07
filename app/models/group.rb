# == Schema Information
# Schema version: 20080409165237
#
# Table name: groups
#
#  id           :integer       not null, primary key
#  name         :string(100)   
#  description  :text          
#  meets        :string(100)   
#  location     :string(100)   
#  directions   :text          
#  other_notes  :text          
#  category     :string(50)    
#  creator_id   :integer       
#  private      :boolean       
#  address      :string(255)   
#  members_send :boolean       default(TRUE)
#  leader_id    :integer       
#  updated_at   :datetime      
#  hidden       :boolean       
#  approved     :boolean       
#  link_code    :string(255)   
#  parents_of   :integer       
#  site_id      :integer       
#

class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :people, :through => :memberships, :order => 'last_name, first_name'
  has_many :messages, :conditions => 'parent_id is null', :order => 'updated_at desc', :dependent => :destroy
  has_many :notes, :order => 'created_at desc'
  has_many :prayer_requests, :order => 'created_at desc'
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'creator_id'
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  belongs_to :parents_of_group, :class_name => 'Group', :foreign_key => 'parents_of'
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  #has_and_belongs_to_many :tags, :order => 'name'
  
  validates_presence_of :name
  validates_presence_of :category
  validates_uniqueness_of :name
  validates_format_of :address, :with => /^[a-zA-Z0-9]+$/, :allow_nil => true
  validates_uniqueness_of :address, :allow_nil => true
  validates_length_of :address, :minimum => 2, :allow_nil => true
  
  serialize :cached_parents
  
  def validate
    begin
      errors.add('parents_of', 'cannot point to self') if not new_record? and parents_of == id
    rescue
      puts 'error checking for self-referencing parents_of (OK if you are migrating)'
    end
  end

  acts_as_photo "#{DB_PHOTO_PATH}/groups", PHOTO_SIZES
  acts_as_logger LogItem
  
  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :model_name => 'Group', :instance_id => id, :changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  def name_group # returns something like "Morgan group"
    "#{name}#{name =~ /group$/i ? '' : ' group'}"
  end
  
  def inspect
    "<#{name}>"
  end
  
  def admins
    memberships.find_all_by_admin(true).map { |m| m.person }
  end
  
  def admin?(person, exclude_global_admins=false)
    if exclude_global_admins
      admins.include? person
    else
      person.admin?(:manage_groups) or admins.include? person
    end
  end
  
  def last_admin?(person)
    (admin? person and not person.admin?(:manage_groups)) and admins.length == 1
  end
  
  def linked?
    link_code and link_code.any?
  end
  
  def get_options_for(person, create_if_missing=false)
    if person.member_of?(self)
      unless options = Membership.find_by_group_id_and_person_id(id, person.id)
        options = Membership.new(:group => self, :person => person)
        options.save if create_if_missing and not person.new_record? and not new_record?
      end
      options
    end
  end
  
  def set_options_for(person, options)
    membership = get_options_for(person) || Membership.new(:group => self, :person => person)
    membership.update_attributes options
  end
  
  alias_method :unlinked_members, :people
  
  def people(select='people.*')
    if parents_of
      update_cached_parents if cached_parents.to_a.empty?
      cached_parent_ids = cached_parents.map { |id| id.to_i }.join(',')
      cached_parent_objects = Person.find(:all, :conditions => "id in (#{cached_parent_ids})", :select => select)
      (unlinked_members.find(:all, :select => select) + cached_parent_objects).uniq.sort_by { |p| [p.last_name, p.first_name] }
    elsif linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions.add_condition ["#{sql_lcase('classes')} = ? or classes like ? or classes like ? or classes like ?", code, "#{code},%", "%,#{code}", "%,#{code},%"], 'or'
      end
      Person.find :all, :conditions => conditions, :order => 'last_name, first_name', :select => select
    else
      unlinked_members.find(:all, :select => select)
    end
  end

  def people_names_and_ids
    #(what.visible_to_everyone? and (full_access? or what.adult?) and what.visible?)
    select = %w(id family_id first_name last_name suffix birthday gender email visible_to_everyone full_access).map { |c| "people.#{c}" }.join(',')
    self.people(select)
  end

  def people_count
    if parents_of
      update_cached_parents if cached_parents.to_a.empty?
      unlinked_members.count('*') + cached_parents.length
    elsif linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions.add_condition ["#{sql_lcase('classes')} = ? or classes like ? or classes like ? or classes like ?", code, "#{code},%", "%,#{code}", "%,#{code},%"], 'or'
      end
      Person.count '*', :conditions => conditions
    else
      unlinked_members.count('*')
    end
  end
  
  after_save :update_cached_parents
  def update_cached_parents
    return unless Group.columns.map { |c| c.name }.include? 'cached_parents'
    if self.parents_of.nil?
      self.cached_parents = []
    else
      ids = Group.find(parents_of).people.map { |p| p.parents }.flatten.uniq.map { |p| p.id }
      self.cached_parents = ids
    end
  end
  
  def can_send?(person)
    (members_send and person.member_of?(self) and person.messages_enabled?) or admin?(person)
  end
  alias_method 'can_post?', 'can_send?'
  
  def full_address
    address.to_s.any? ? (address + '@' + Site.current.host) : nil
  end
  
  class << self
    def update_cached_parents
      find(:all).each { |group| group.save }
    end
  end
end
