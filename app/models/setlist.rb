# == Schema Information
# Schema version: 89
#
# Table name: setlists
#
#  id         :integer       not null, primary key
#  start      :datetime      
#  person_id  :integer       
#  created_at :datetime      
#

class Setlist < ActiveRecord::Base
  has_many :performances
  has_many :songs, :through => :performances
end
