# == Schema Information
# Schema version: 1
#
# Table name: performances
#
#  id         :integer       not null, primary key
#  setlist_id :integer       
#  song_id    :integer       
#  ordering   :integer       
#  site_id    :integer       
#

class Performance < ActiveRecord::Base
  belongs_to :song
  belongs_to :setlist
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  acts_as_logger LogItem
end
