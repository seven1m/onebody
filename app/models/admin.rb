# == Schema Information
# Schema version: 76
#
# Table name: admins
#
#  id                     :integer(11)   not null, primary key
#  manage_publications    :boolean(1)    
#  manage_log             :boolean(1)    
#  manage_music           :boolean(1)    
#  view_hidden_properties :boolean(1)    
#  edit_profiles          :boolean(1)    
#  manage_groups          :boolean(1)    
#  manage_shares          :boolean(1)    
#  manage_notes           :boolean(1)    
#  manage_messages        :boolean(1)    
#  view_hidden_profiles   :boolean(1)    
#  manage_prayer_signups  :boolean(1)    
#  manage_comments        :boolean(1)    
#  manage_events          :boolean(1)    
#  manage_recipes         :boolean(1)    
#  manage_pictures        :boolean(1)    
#  manage_access          :boolean(1)    
#  view_log               :boolean(1)    
#  manage_updates         :boolean(1)    
#  created_at             :datetime      
#  updated_at             :datetime      
#

class Admin < ActiveRecord::Base
  has_one :person
  
  def self.privilege_columns
    columns.select { |c| !['id', 'created_at', 'updated_at'].include? c.name }
  end
end
