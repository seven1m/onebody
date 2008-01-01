# == Schema Information
# Schema version: 89
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
#

class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :song
end
