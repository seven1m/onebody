# == Schema Information
# Schema version: 20080409165237
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
  belongs_to :person, :include => :family, :conditions => ['people.visible = ? and families.visible = ?', true, true]
  belongs_to :group
  has_many :comments, :dependent => :destroy
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_logger LogItem
  
  validates_presence_of :title
  validates_presence_of :body
  
  def name; title; end

  def person_name
    Person.find_by_sql(["select people.family_id, people.first_name, people.last_name, people.suffix from people left outer join families on families.id = people.family_id where people.id = ? and people.visible = ? and families.visible = ?", self.person_id.to_i, true, true]).first.name rescue nil
  end
end
