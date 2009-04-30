# == Schema Information
#
# Table name: notes
#
#  id           :integer       not null, primary key
#  person_id    :integer       
#  title        :string(255)   
#  body         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  original_url :string(255)   
#  deleted      :boolean       
#  group_id     :integer       
#  site_id      :integer       
#

class Note < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  has_many :comments, :dependent => :destroy
  belongs_to :site
  
  scope_by_site_id
  
  acts_as_logger LogItem
  
  validates_presence_of :title
  validates_presence_of :body
  
  def name; title; end
  
  def group_id=(id)
    if group = Group.find_by_id(id) and group.can_post?(Person.logged_in)
      write_attribute :group_id, id
    else
      write_attribute :group_id, nil
    end
  end

  def person_name
    Person.find_by_sql(["select people.family_id, people.first_name, people.last_name, people.suffix from people left outer join families on families.id = people.family_id where people.id = ? and people.visible = ? and families.visible = ?", self.person_id.to_i, true, true]).first.name rescue nil
  end
end
