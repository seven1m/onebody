# == Schema Information
# Schema version: 20080409165237
#
# Table name: attachments
#
#  id           :integer       not null, primary key
#  message_id   :integer       
#  name         :string(255)   
#  file         :binary(104857 
#  content_type :string(50)    
#  created_at   :datetime      
#  song_id      :integer       
#  site_id      :integer       
#

class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :song
  belongs_to :site
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  acts_as_file DB_ATTACHMENTS_PATH
  
  def visible_to?(person)
    (message and person.can_see?(message)) or
    (song and person.can_see?(song))
  end
end
