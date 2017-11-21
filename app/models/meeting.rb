class Meeting < ApplicationRecord
  has_many :meeting_memberships
  has_many :people, through: :meeting_memberships
end
