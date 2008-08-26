# == Schema Information
#
# Table name: groups
#
#  id             :integer       not null, primary key
#  name           :string(100)   
#  description    :text          
#  meets          :string(100)   
#  location       :string(100)   
#  directions     :text          
#  other_notes    :text          
#  category       :string(50)    
#  creator_id     :integer       
#  private        :boolean       
#  address        :string(255)   
#  members_send   :boolean       default(TRUE)
#  leader_id      :integer       
#  updated_at     :datetime      
#  hidden         :boolean       
#  approved       :boolean       
#  link_code      :string(255)   
#  parents_of     :integer       
#  site_id        :integer       
#  cached_parents :text          
#  blog           :boolean       default(TRUE)
#  email          :boolean       default(TRUE)
#  prayer         :boolean       default(TRUE)
#  attendance     :boolean       default(TRUE)
#

class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :people, :through => :memberships, :order => 'last_name, first_name'
  has_many :messages, :conditions => 'parent_id is null', :order => 'updated_at desc', :dependent => :destroy
  has_many :notes, :order => 'created_at desc'
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :attendance_records
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'creator_id'
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  belongs_to :parents_of_group, :class_name => 'Group', :foreign_key => 'parents_of'
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
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
    LogItem.create :model_name => 'Group', :instance_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
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
    unlinked = unlinked_members.find(:all, :select => select+',0 as linked')
    if parents_of
      update_cached_parents if cached_parents.to_a.empty?
      cached_parent_ids = cached_parents.map { |id| id.to_i }.join(',')
      cached_parent_objects = Person.find(:all, :conditions => "id in (#{cached_parent_ids})", :select => select + ',1 as linked')
      (cached_parent_objects + unlinked).uniq.sort_by { |p| [p.last_name, p.first_name] }
    elsif linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions.add_condition ["#{sql_lcase('classes')} = ? or classes like ? or classes like ? or classes like ?", code, "#{code},%", "%,#{code}", "%,#{code},%"], 'or'
      end
      linked = Person.find(:all, :conditions => conditions, :order => 'last_name, first_name', :select => select + ',1 as linked')
      (linked + unlinked).uniq.sort_by { |p| [p.last_name, p.first_name] }
    else
      unlinked
    end
  end

  def people_names_and_ids
    select = %w(id family_id first_name last_name suffix birthday gender email visible_to_everyone full_access classes).map { |c| "people.#{c}" }.join(',')
    self.people(select)
  end

  def people_count
    if parents_of
      update_cached_parents if cached_parents.to_a.empty?
      unlinked_members.count('*') + cached_parents.length
    elsif linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions << "#{sql_lcase('classes')} = #{Person.connection.quote(code)}"
        conditions << "classes like #{Person.connection.quote(code + ',%')}"
        conditions << "classes like #{Person.connection.quote('%,' + code)}"
        conditions << "classes like #{Person.connection.quote('%,' + code + ',%')}"
      end
      linked_ids = Person.connection.select_values("select id from people where #{conditions.join(' or ')}")
      linked_ids.length + unlinked_members.count('*', :conditions => linked_ids.any? && "people.id not in (#{linked_ids.join(',')})")
    else
      unlinked_members.count('*')
    end
  end
  
  before_save :update_cached_parents
  def update_cached_parents
    return unless Group.columns.map { |c| c.name }.include? 'cached_parents'
    if self.parents_of.nil?
      self.cached_parents = []
    elsif self.parents_of != self.id
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
  
  def get_people_attendance_records_for_date(date)
    records = {}
    people.each { |p| records[p.id] = [p, false] }
    attendance_records.find_all_by_attended_at(date.to_time).each do |record|
      records[record.person.id] = [record.person, record]
    end
    records.values.sort_by { |r| r[0].name }
  end
  
  def attendance_dates
    attendance_records.find_by_sql("select distinct attended_at from attendance_records where group_id = #{id} order by attended_at desc").map { |r| r.attended_at }
  end
  
  class << self
    def update_cached_parents
      find(:all).each { |group| group.save }
    end
    
    def categories
      returning({}) do |cats|
        if Person.logged_in.admin?(:manage_groups)
          results = Group.find_by_sql("select category, count(*) as group_count from groups where category is not null and category != '' and category != 'Subscription' group by category").map { |g| [g.category, g.group_count] }
        else
          results = Group.find_by_sql(["select category, count(*) as group_count from groups where category is not null and category != '' and category != 'Subscription' and hidden = ? and approved = ? group by category", false, true]).map { |g| [g.category, g.group_count] }
        end
        results.each do |cat, count|
          cats[cat] = count.to_i
        end
      end
    end
  end
end
