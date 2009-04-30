# == Schema Information
#
# Table name: service_categories
#
#  id          :integer       not null, primary key
#  name        :string(255)   not null
#  description :text          
#  site_id     :integer       
#

class ServiceCategory < ActiveRecord::Base
  has_many :services, :dependent => :destroy
  has_many :people, :through => :services
  belongs_to :site
  
  scope_by_site_id

  validates_presence_of :name
  
  def destroyable?
    self.people.empty?
  end
end
