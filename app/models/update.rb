class Update < ActiveRecord::Base
  belongs_to :person
  paranoid_attributes :first_name, :last_name, :address1, :address2, :city, :state, :zip
end
