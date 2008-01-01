# == Schema Information
# Schema version: 89
#
# Table name: contacts
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  owner_id   :integer       
#  updated_at :datetime      
#

class Contact < ActiveRecord::Base
  belongs_to :person
  belongs_to :owner, :class_name => 'Person', :foreign_key => 'owner_id'
  
  acts_as_logger LogItem
end
