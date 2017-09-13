require 'active_support/concern'

module Concerns
  module Person
    module EmailChanged
      extend ActiveSupport::Concern

      included do
        scope :email_changed, -> { undeleted.where(email_changed: true) }
        attr_accessor :dont_mark_email_changed
        before_update :mark_email_changed
      end

      # overwrite the method created by ActiveModel::Dirty of the same name
      def email_changed?
        self[:email_changed]
      end

      def mark_email_changed
        return if dont_mark_email_changed
        return unless will_save_change_to_attribute?('email')
        self[:email_changed] = true
        Notifier.email_update(self).deliver_now
      end
    end
  end
end
