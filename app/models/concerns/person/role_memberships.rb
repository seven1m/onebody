require 'active_support/concern'

module Concerns
  module Person
    module RoleMemberships
      extend ActiveSupport::Concern

      included do
        has_many :role_memberships, dependent: :destroy
        has_many :roles, through: :role_memberships
        after_destroy :destroy_role_memberships
      end

      def has_role?(role)
        role_memberships.where(role_id: role.id).any?
      end

      def has_any_role?()
        role_memberships.all().any?
      end

      def destroy_role_memberships
        role_memberships.destroy_all
      end
    end
  end
end
