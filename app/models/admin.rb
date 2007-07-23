# == Schema Information
# Schema version: 65
#
# Table name: admins
#
#  id                     :integer(11)   not null, primary key
#  manage_publications    :boolean(1)    
#  manage_log             :boolean(1)    
#  manage_music           :boolean(1)    
#  view_music             :boolean(1)    
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
#

class Admin < ActiveRecord::Base
  has_one :person
end
