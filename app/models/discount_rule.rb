class DiscountRule < ActiveRecord::Base
  scope_by_site_id
  belongs_to :event
  belongs_to :if_registrant_type, class_name: 'RegistrantType'
  belongs_to :then_registrant_type, class_name: 'RegistrantType'

  validates :event, :if_registrant_type, :then_registrant_type, presence: true
  validates :kind, inclusion: %w(registration registrant)
end
