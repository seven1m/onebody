class Donation < ActiveRecord::Base
  belongs_to :person
  belongs_to :family

  monetize :amount_cents
end
