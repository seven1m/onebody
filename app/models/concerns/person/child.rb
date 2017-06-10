require 'active_support/concern'

module Concerns
  module Person
    module Child
      extend ActiveSupport::Concern

      included do
        after_initialize :guess_child, if: ->(p) { p.child.nil? && p.birthday.nil? }
        validates :child, inclusion: [true, false], unless: ->(p) { p.deleted? }
        before_validation :set_child
      end

      def guess_child
        self.child = if family
                       family.people.undeleted.count >= 2
                     else
                       false
                     end
      end

      def set_child
        return unless birthday && birthday.year != 1900
        self.child = !at_least?(Setting.get(:system, :adult_age).to_i)
        true # don't return false or validation will fail
      end

      def at_least?(age)
        return false unless y = years_of_age
        y >= age
      end

      def years_of_age(on = Date.current)
        return nil unless birthday
        return nil if birthday.year == 1900
        years = on.year - birthday.year
        years -= 1 if on.month < birthday.month
        years -= 1 if on.month == birthday.month && on.day < birthday.day
        years
      end

      def adult?
        !child?
      end
    end
  end
end
