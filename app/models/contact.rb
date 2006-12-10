class Contact < ActiveRecord::Base
  belongs_to :person
  belongs_to :owner, :class_name => 'Person'
end
