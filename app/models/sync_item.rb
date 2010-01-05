# == Schema Information
#
# Table name: sync_items
#
#  id             :integer       not null, primary key
#  site_id        :integer       
#  sync_id        :integer       
#  syncable_id    :integer       
#  syncable_type  :string(255)   
#  legacy_id      :integer       
#  name           :string(255)   
#  operation      :string(50)    
#  status         :string(50)    
#  error_messages :text          
#

class SyncItem < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id
  
  serialize :error_messages
  
  belongs_to :sync
  belongs_to :syncable, :polymorphic => true
end
