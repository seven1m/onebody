class RoleMembership < ApplicationRecord
    include Authority::Abilities
    self.authorizer_name = 'RoleMembershipAuthorizer'

    belongs_to :role
    belongs_to :person

    validates_uniqueness_of :role_id, scope: %i(site_id person_id)

    scope_by_site_id

    scope :order_by_birthday, -> { order('ifnull(month(people.birthday), 99)') }
    scope :order_by_name,     -> { order('people.first_name, people.last_name') }
end  