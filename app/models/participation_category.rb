class ParticipationCategory < ActiveRecord::Base
  has_many :participations, :dependent => :destroy
  has_many :people, :through => :participations
end
