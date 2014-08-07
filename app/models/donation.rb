class Donation < ActiveRecord::Base
  belongs_to :person
  belongs_to :family
end
