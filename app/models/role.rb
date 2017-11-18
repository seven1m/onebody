class Role < ApplicationRecord
    include Authority::Abilities
    self.authorizer_name = 'RoleAuthorizer'

    has_many :role_memberships, dependent: :destroy
    has_many :people, -> { order(:last_name, :first_name) }, through: :role_memberships
end