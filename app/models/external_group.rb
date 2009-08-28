# == Schema Information
#
# Table name: external_groups
#
#  id          :integer       not null, primary key
#  name        :string(255)   
#  category    :string(1000)  
#  external_id :integer       
#  site_id     :integer       
#  created_at  :datetime      
#  updated_at  :datetime      
#

class ExternalGroup < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id
  validates_presence_of :name
end
