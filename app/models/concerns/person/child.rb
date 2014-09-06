require 'active_support/concern'

module Concerns
  module Person
    module Child
      extend ActiveSupport::Concern

      included do
        after_initialize :guess_child, if: -> p { p.child.nil? and p.birthday.nil? }
        validates :child, inclusion: [true, false], unless: -> p { p.deleted? }
        before_validation :set_child
      end

      def guess_child
        if family
          self.child = family.people.undeleted.count >= 2
        else
          self.child = false
        end
      end

      def set_child
        return unless birthday
        self.child = !at_least?(Setting.get(:system, :adult_age).to_i)
        true # don't return false or validation will fail
      end

      def at_least?(age)
        (y = years_of_age and y >= age)
      end

      def age
        birthday && birthday.distance_to(Date.today)
      end

      def years_of_age(on = Date.today)
        return nil unless birthday
        return nil if birthday.year == 1900
        years = on.year - birthday.year
        years -= 1 if on.month < birthday.month
        years -= 1 if on.month == birthday.month and on.day < birthday.day
        years
      end

      def adult?
        not child?
      end

    end
  end
end
