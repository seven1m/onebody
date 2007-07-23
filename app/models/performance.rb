# == Schema Information
# Schema version: 66
#
# Table name: performances
#
#  id         :integer(11)   not null, primary key
#  setlist_id :integer(11)   
#  song_id    :integer(11)   
#  ordering   :integer(11)   
#

# == Schema Information
# Schema version: 64
#
# Table name: performances
#
#  id         :integer(11)   not null, primary key
#  setlist_id :integer(11)   
#  song_id    :integer(11)   
#  ordering   :integer(11)   
#

class Performance < ActiveRecord::Base
  belongs_to :song
  belongs_to :setlist
  
  acts_as_logger LogItem
end
