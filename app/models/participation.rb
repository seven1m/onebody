class Participation < ActiveRecord::Base
  belongs_to :person
  belongs_to :participation_category
end
