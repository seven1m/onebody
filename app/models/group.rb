# == Schema Information
# Schema version: 74
#
# Table name: groups
#
#  id           :integer(11)   not null, primary key
#  name         :string(100)   
#  description  :text          
#  meets        :string(100)   
#  location     :string(100)   
#  directions   :text          
#  other_notes  :text          
#  category     :string(50)    
#  creator_id   :integer(11)   
#  private      :boolean(1)    
#  address      :string(255)   
#  members_send :boolean(1)    default(TRUE)
#  leader_id    :integer(11)   
#  updated_at   :datetime      
#  hidden       :boolean(1)    
#  approved     :boolean(1)    
#  link_code    :string(255)   
#

class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :people, :through => :memberships, :order => 'last_name, first_name'
  has_many :messages, :conditions => 'parent_id is null', :order => 'updated_at desc', :dependent => :destroy
  has_many :notes, :order => 'created_at desc'
  has_many :prayer_requests, :order => 'created_at desc'
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'creator_id'
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  #has_and_belongs_to_many :tags, :order => 'name'
  
  validates_presence_of :name
  validates_presence_of :category
  validates_uniqueness_of :name
  validates_format_of :address, :with => /^[a-zA-Z0-9]+$/, :allow_nil => true
  validates_uniqueness_of :address, :allow_nil => true
  validates_length_of :address, :minimum => 2, :allow_nil => true
    
  acts_as_photo 'db/photos/groups', PHOTO_SIZES
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
    if private? or exclude_global_admins
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
    unless options = Membership.find_by_group_id_and_person_id(id, person.id)
      options = Membership.new(:group => self, :person => person)
      options.save if create_if_missing and not person.new_record? and not new_record?
    end
    options
  end
  
  def set_options_for(person, options)
    membership = get_options_for(person) || Membership.new(:group => self, :person => person)
    membership.update_attributes options
  end
  
  alias_method :unlinked_members, :people
  
  def people
    if linked?
      conditions = []
      link_code.downcase.split.each do |code|
        conditions.add_condition ['LCASE(classes) = ? or classes like ? or classes like ? or classes like ?', code, "#{code},%", "%,#{code}", "%,#{code},%"], 'or'
      end
      Person.find :all, :conditions => conditions, :order => 'last_name, first_name'
    else
      unlinked_members
    end
  end
  
  def can_send?(person)
    (members_send and people.include?(person) and person.messages_enabled?) or admin?(person)
  end
  alias_method 'can_post?', 'can_send?'
  
  def full_address
    address.to_s.any? ? (address + '@' + SETTINGS['contact']['group_address_domains'].first) : nil
  end
end
