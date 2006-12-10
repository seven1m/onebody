class Worker < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :person
end
