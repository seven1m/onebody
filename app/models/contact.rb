# == Schema Information
# Schema version: 4
#
# Table name: contacts
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  owner_id   :integer       
#  updated_at :datetime      
#  site_id    :integer       
#

class Contact < ActiveRecord::Base
  belongs_to :person
  belongs_to :owner, :class_name => 'Person', :foreign_key => 'owner_id'
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  acts_as_logger LogItem
end
