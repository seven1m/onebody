# == Schema Information
#
# Table name: groups
#
#  id                        :integer       not null, primary key
#  name                      :string(100)   
#  description               :text          
#  meets                     :string(100)   
#  location                  :string(100)   
#  directions                :text          
#  other_notes               :text          
#  category                  :string(50)    
#  creator_id                :integer       
#  private                   :boolean       
#  address                   :string(255)   
#  members_send              :boolean       default(TRUE)
#  leader_id                 :integer       
#  updated_at                :datetime      
#  hidden                    :boolean       
#  approved                  :boolean       
#  link_code                 :string(255)   
#  parents_of                :integer       
#  site_id                   :integer       
#  blog                      :boolean       default(TRUE)
#  email                     :boolean       default(TRUE)
#  prayer                    :boolean       default(TRUE)
#  attendance                :boolean       default(TRUE)
#  legacy_id                 :integer       
#  gcal_private_link         :string(255)   
#  approval_required_to_join :boolean       default(TRUE)
#  pictures                  :boolean       default(TRUE)
#

class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :people, :through => :memberships, :order => 'last_name, first_name'
  has_many :admins, :through => :memberships, :source => :person, :order => 'last_name, first_name', :conditions => ['memberships.admin = ?', true]
  has_many :messages, :conditions => 'parent_id is null', :order => 'updated_at desc', :dependent => :destroy
  has_many :notes, :order => 'created_at desc'
  has_many :prayer_requests, :order => 'created_at desc'
  has_many :attendance_records
  has_many :albums
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'creator_id'
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  belongs_to :parents_of_group, :class_name => 'Group', :foreign_key => 'parents_of'
  belongs_to :site
  
  scope_by_site_id
  
  validates_presence_of :name
  validates_presence_of :category
  validates_uniqueness_of :name
  validates_format_of :address, :with => /^[a-zA-Z0-9]+$/, :allow_nil => true
  validates_uniqueness_of :address, :allow_nil => true
  validates_length_of :address, :in => 2..30, :allow_nil => true
  
  serialize :cached_parents
  
  def validate
    begin
      errors.add('parents_of', 'cannot point to self') if not new_record? and parents_of == id
    rescue
      puts 'error checking for self-referencing parents_of (OK if you are migrating)'
    end
  end

  has_one_photo :path => "#{DB_PHOTO_PATH}/groups", :sizes => PHOTO_SIZES
  acts_as_logger LogItem
  
  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :loggable_type => 'Group', :loggable_id => id, :object_changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  def name_group # returns something like "Morgan group"
    "#{name}#{name =~ /group$/i ? '' : ' group'}"
  end
  
  def inspect
    "<#{name}>"
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
  
  def leader_with_guessing
    leader_without_guessing || admins.first
  end
  alias_method_chain :leader, :guessing
  
  def get_options_for(person, create_if_missing=false) # TODO: remove create_if_missing option (not used)
    memberships.find_by_person_id(person.id)
  end
  
  def set_options_for(person, options)
    memberships.find_by_person_id(person.id).update_attributes!(options)
  end
  
  after_save :update_memberships
  
  def update_memberships
    if parents_of
      parents = Group.find(parents_of).people.map { |p| p.parents }.flatten.uniq
      update_membership_associations(parents)
    elsif linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions.add_condition ["#{sql_lcase('classes')} = ? or classes like ? or classes like ? or classes like ?", code, "#{code},%", "%,#{code}", "%,#{code},%"], 'or'
      end
      update_membership_associations(Person.find(:all, :conditions => conditions))
    elsif Membership.column_names.include?('auto')
      memberships.find_all_by_auto(true).each { |m| m.destroy }
    end
  end
  
  def update_membership_associations(new_people)
    self.people.reload
    (new_people - self.people).each { |p| memberships.create!(:person => p, :auto => true) }
    (self.people - new_people).each { |p| m = memberships.find_by_person_id(p.id); m.destroy if m.auto? }
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
  
  def gcal_url
    if gcal_private_link.to_s.any?
      account = gcal_account
      if token = gcal_token
        "http://www.google.com/calendar/embed?pvttk=#{token}&amp;showTitle=0&amp;showCalendars=0&amp;height=600&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;src=#{account}&amp;color=%23A32929&amp;ctz=UTC#{Time.zone.utc_offset}"
      end
    end
  end
  
  def gcal_account
  	account = gcal_private_link.to_s.match(/[^\/]+[@(%40)][^\/]+/).to_s.sub(/@/, '%40')
	if account[0,5] == "embed"
		idx1 = (account =~ /src=/) + 4
		idx2 = (account =~ /\&/) - idx1
		account = account[idx1, idx2]
	end
	account
  end
  
  def gcal_token
  	gcal_private_link.to_s.match(/private\-([a-z0-9]+)/)[1]
  end 
  
  before_destroy :remove_parent_of_links
  
  def remove_parent_of_links
    Group.find_all_by_parents_of(id).each { |g| g.update_attribute(:parents_of, nil) }
  end
  
  def sync_with_campaign_monitor(api_key, list_id)
    cm = CampaignMonitor.new(api_key)
    in_group = self.people.all(:conditions => ['memberships.get_email = ?', true]).select { |p| p.email.to_s.any? }
    unsubscribed = cm.Subscribers.GetUnsubscribed('ListID' => list_id, 'Date' => '2000-01-01 00:00:00')['anyType']['Subscriber'].to_a.map { |s| [s['Name'], s['EmailAddress']] }
    # ensure we don't resubscribe someone who has already unsubscribed
    # (and also set their get_email attribute to false in the group)
    upload_to_cm = []
    in_group.each do |person|
      if unsubscribed.map { |p| p[0] }.include?(person.name) or
        unsubscribed.map { |p| p[1] }.include?(person.email)
        person.memberships.find_by_group_id(self.id).update_attribute(:get_email, false)
      else
        upload_to_cm << [person.name, person.email]
      end
    end
    # unsubscribe addresses in the subscriber list but not found in the group
    subscribed = cm.Subscribers.GetActive('ListID' => list_id, 'Date' => '2000-01-01 00:00:00')['anyType']['Subscriber'].to_a.map { |s| [s['Name'], s['EmailAddress']] }
    subscribed.each do |name, email|
      if not upload_to_cm.any? { |n, e| e == email }
        cm.Subscriber.Unsubscribe('ListID' => list_id, 'Email' => email)
      end
    end
    # subscribe addresses in the group but not in the subscriber list
    upload_to_cm.each do |name, email|
      if not subscribed.any? { |n, e| e == email }
        cm.Subscriber.Add('ListID' => list_id, 'Email' => email, 'Name' => name)
      end
    end
  end
  
  class << self
    def update_memberships
      find(:all).each { |group| group.update_memberships }
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
