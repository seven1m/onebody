require 'active_support/concern'

module ChildConcern
  extend ActiveSupport::Concern

  included do
    after_initialize :guess_child, if: -> p { p.child.nil? and p.birthday.nil? }
    validate :validate_child, unless: -> p { p.deleted? }

    alias_method :birthday_without_child=, :birthday=
    remove_method :birthday=
  end

  def guess_child
    return unless family
    self.child = family.people.undeleted.count >= 2
  end

  def birthday=(d)
    self.birthday_without_child = d
    self.child = nil if years_of_age
  end

  def at_least?(age) # assumes you won't pass in anything over 18
    (y = years_of_age and y >= age) or child == false
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

  def adult?; at_least?(Setting.get(:system, :adult_age).to_i); end

  protected

  def validate_child
    y = years_of_age
    if child == true and y and y >= 13
      errors.add :child, :cannot_be_yes
    elsif child == false and y and y < 13
      errors.add :child, :cannot_be_no
    elsif child.nil? and y.nil?
      errors.add :child, :blank
    end
  end

end
