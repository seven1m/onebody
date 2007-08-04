# == Schema Information
# Schema version: 78
#
# Table name: attachments
#
#  id           :integer(11)   not null, primary key
#  message_id   :integer(11)   
#  name         :string(255)   
#  file         :binary        
#  content_type :string(50)    
#  created_at   :datetime      
#  song_id      :integer(11)   
#

class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :song
end
