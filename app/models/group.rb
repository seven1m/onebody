class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :people, :through => :memberships
  has_many :messages, :conditions => 'parent_id is null', :order => 'updated_at desc'
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'creator_id'
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  has_and_belongs_to_many :tags, :order => 'name'
  
  validates_presence_of :name
  validates_presence_of :category
  validates_uniqueness_of :name
  validates_format_of :address, :with => /^[a-zA-Z0-9]+$/
  validates_uniqueness_of :address
  validates_length_of :address, :minimum => 6, :allow_nil => true
  validates_presence_of :creator_id
  
  acts_as_photo 'db/photos/groups', PHOTO_SIZES
  
  def inspect
    "<#{name}>"
  end
  
  def admins
    memberships.find_all_by_admin(true).map { |m| m.person }
  end
  
  def admin?(person)
    person.admin? or admins.include? person
  end
  
  def last_admin?(person)
    (admin? person and not person.admin?) and admins.length == 1
  end
  
  def linked?
    link_code and link_code.any?
  end
  
  def get_options_for(person)
    Membership.find_by_group_id_and_person_id(id, person.id)
  end
  
  def set_options_for(person, options)
    membership = get_options_for(person) || Membership.new(:group => self, :person => person)
    membership.update_attributes options
  end
  
  alias_method :members, :people
  
  def people
    if linked?
      Person.find :all, :conditions => ['LCASE(classes) = ? or classes like ? or classes like ? or classes like ?', link_code.downcase, "#{link_code},%", "%,#{link_code}", "%,#{link_code},%"], :order => 'last_name, first_name'
    else
      members
    end
  end
  
  def can_send?(person)
    (members_send and people.include? person) or admin? person
  end
  alias_method 'can_post?', 'can_send?'
end
