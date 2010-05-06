require File.dirname(__FILE__) + '/../test_helper'

class UpdateTest < ActiveSupport::TestCase
  fixtures :updates, :people

  should "update a person" do
    Person.logged_in = people(:tim)
    assert updates(:update_jeremy).do!
    %w(first_name last_name suffix gender mobile_phone work_phone fax).each do |attribute|
      assert_equal updates(:update_jeremy)[attribute], people(:jeremy)[attribute]
    end
    %w(birthday anniversary).each do |attribute|
      assert_equal updates(:update_jeremy)[attribute].to_s, people(:jeremy)[attribute].to_s
    end
    %w(home_phone address1 address2 city state zip family_name family_last_name).each do |attribute|
      assert_equal updates(:update_jeremy)[attribute], people(:jeremy).family[attribute.sub(/^family_/, '')]
    end
  end

  should "list only the changes" do
    # better than nothing
    assert_equal 9, updates(:update_jeremy).changes.keys.length
  end

end
