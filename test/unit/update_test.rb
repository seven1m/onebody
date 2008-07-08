require File.dirname(__FILE__) + '/../test_helper'

class UpdateTest < Test::Unit::TestCase
  fixtures :updates, :people

  def test_update
    Person.logged_in = people(:tim)
    assert updates(:update_tim).do!
    people(:tim).reload
    %w(first_name last_name suffix gender mobile_phone work_phone fax).each do |attribute|
      assert_equal updates(:update_tim)[attribute], people(:tim)[attribute]
    end
    %w(birthday anniversary).each do |attribute|
      if updates(:update_tim)[attribute].to_s =~ /1800/
        assert_equal nil, people(:tim)[attribute]
      else
        assert_equal updates(:update_tim)[attribute].to_s, people(:tim)[attribute].to_s
      end
    end
    %w(home_phone address1 address2 city state zip family_name family_last_name).each do |attribute|
      assert_equal updates(:update_tim)[attribute], people(:tim).family[attribute.gsub(/^family_/, '')]
    end
  end
end
