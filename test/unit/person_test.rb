require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase
  fixtures :people, :families
  
  def test_email_address_unique_within_family
    # tim already has email address morgans@somedomain.com
    p = people(:peter)
    p.email = 'morgans@somedomain.com'
    p.save
    assert_equal 'already taken by someone else.', p.errors[:email]
  end
  
  def test_email_address_format
    # test every character allowed
    p = people(:peter)
    p.email = 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com'
    p.save
    assert_nil p.errors[:email]
    # test what we have in our fixtures
    Person.find(:all).select { |p| p.email }.each do |p|
      p.save
      assert_nil p.errors[:email]
    end
    # test a bad one
    p = people(:peter)
    p.email = 'bad address@example.com'
    p.save
    assert_equal 'not a valid email address.', p.errors[:email]
  end
  
  def test_website
    # good
    p = people(:peter)
    p.website = 'http://goodwebsite.com/a/path?some=args'
    p.save
    assert_nil p.errors[:website]
    # bad
    p.website = "javascript://void(alert('do evil stuff'))"
    p.save
    assert_equal 'is invalid', p.errors[:website]
  end
  
  def test_name
    # can see name
    Person.logged_in = people(:tim)
    assert_equal 'Mac Morgan', Person.find(people(:mac).id).name # must do a fresh load
    # cannot see name
    Person.logged_in = people(:peter)
    assert_equal '???', Person.find(people(:mac).id).name # must do a fresh load
    # can see name
    people(:mac).update_attribute :parental_consent, 'yes'
    assert_equal 'Mac Morgan', Person.find(people(:mac).id).name # must do a fresh load
  end
  
  def test_sharing
    # family = true, person = false, peter should not see
    families(:morgan).update_attribute :share_mobile_phone, true
    people(:jennie).update_attribute :share_mobile_phone, false
    assert !people(:jennie).share_mobile_phone_with(people(:peter))
    # family = false, person = true, peter should see
    families(:morgan).update_attribute :share_mobile_phone, false
    people(:jennie).update_attribute :share_mobile_phone, true
    assert people(:jennie).share_mobile_phone_with(people(:peter))
    # family = true, person = nil, peter should see
    families(:morgan).update_attribute :share_mobile_phone, true
    people(:jennie).update_attributes :share_mobile_phone => nil
    assert people(:jennie).share_mobile_phone_with(people(:peter))
    # family = false, person = nil, peter should not see
    families(:morgan).update_attribute :share_mobile_phone, false
    people(:jennie).update_attributes :share_mobile_phone => nil
    assert !people(:jennie).share_mobile_phone_with(people(:peter))
  end
end
