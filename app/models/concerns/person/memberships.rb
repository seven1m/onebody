require 'active_support/concern'

module Concerns
  module Person
    module Memberships
      extend ActiveSupport::Concern

      included do
        has_many :memberships, dependent: :destroy
        has_many :membership_requests, dependent: :destroy
        has_many :groups, through: :memberships
        after_destroy :destroy_memberships
      end

      def member_of?(group)
        memberships.where(group_id: group.id).any?
      end

      def destroy_memberships
        memberships.destroy_all
        membership_requests.destroy_all
      end
    end
  end
end
