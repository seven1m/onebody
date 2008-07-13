# == Schema Information
# Schema version: 20080709134559
#
# Table name: sync_instances
#
#  id                :integer       not null, primary key
#  site_id           :integer       
#  owner_id          :integer       
#  person_id         :integer       
#  remote_id         :integer       
#  remote_account_id :integer       
#  account_type      :string(25)    
#  created_at        :datetime      
#  updated_at        :datetime      
#

class SyncInstance < ActiveRecord::Base
  belongs_to :site
  belongs_to :person
  belongs_to :owner, :class_name => 'Person'
  belongs_to :remote_account
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def update_remote_person
    self.remote_account.update_remote_person(self.person)
  end
end
