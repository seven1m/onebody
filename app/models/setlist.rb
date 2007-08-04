# == Schema Information
# Schema version: 78
#
# Table name: setlists
#
#  id         :integer(11)   not null, primary key
#  start      :datetime      
#  person_id  :integer(11)   
#  created_at :datetime      
#

class Setlist < ActiveRecord::Base
  has_many :performances
  has_many :songs, :through => :performances
end
