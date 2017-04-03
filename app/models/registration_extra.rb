class RegistrationExtra < ActiveRecord::Base
  scope_by_site_id

  belongs_to :object, polymorphic: true

  validates :object, :count, presence: true
end
