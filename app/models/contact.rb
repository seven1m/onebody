# == Schema Information
# Schema version: 69
#
# Table name: contacts
#
#  id         :integer(11)   not null, primary key
#  person_id  :integer(11)   
#  owner_id   :integer(11)   
#  updated_at :datetime      
#

class Contact < ActiveRecord::Base
  belongs_to :person
  belongs_to :owner, :class_name => 'Person', :foreign_key => 'owner_id'
  
  acts_as_logger LogItem
end
