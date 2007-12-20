require File.dirname(__FILE__) + '/../test_helper'

class UpdateTest < Test::Unit::TestCase
  fixtures :updates, :people

  # Replace this with your real tests.
  def test_update
    Person.logged_in = people(:tim)
    updates(:update_tim).do!
    people(:tim).reload
    %w(first_name last_name
      home_phone mobile_phone work_phone fax
      address1 address2 city state zip
      birthday anniversary).each do |attribute|
      assert_equal updates(:update_tim)[attribute], people(:tim)[attribute]
    end
  end
end
