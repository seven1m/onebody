require 'active_support/concern'

module Concerns
  module Person
    module Administrator
      extend ActiveSupport::Concern

      included do
        after_destroy :destroy_admin
      end

      def admin?(perm = nil)
        if super_admin?
          true
        elsif perm
          admin && admin.flags[perm.to_s]
        else
          admin ? true : false
        end
      end

      def super_admin?
        admin.try(:super_admin?)
      end

      def destroy_admin
        return unless admin && admin.template_name.nil?
        admin.destroy
      end
    end
  end
end
