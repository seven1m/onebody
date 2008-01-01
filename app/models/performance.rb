# == Schema Information
# Schema version: 89
#
# Table name: performances
#
#  id         :integer       not null, primary key
#  setlist_id :integer       
#  song_id    :integer       
#  ordering   :integer       
#

class Performance < ActiveRecord::Base
  belongs_to :song
  belongs_to :setlist
  
  acts_as_logger LogItem
end
