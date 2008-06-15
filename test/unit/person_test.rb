require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase
  fixtures :people, :families
  
  def test_member_of
    Group.find(:all).each do |group|
      group.people.each do |person|
        assert person.member_of?(group)
      end
    end
  end
  
  def test_email_address_unique_within_family
    # tim already has email address
    p = people(:peter)
    p.email = people(:tim).email
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
  
  def test_sharing
    # update_attribute to nil doesn't seem to work for booleans on fixture instantiated instances
    f = families(:morgan); p = Person.find(people(:jennie).id)
    # family = true, person = false, peter should not see
    f.update_attribute :share_mobile_phone, true
    p.update_attribute :share_mobile_phone, false
    assert !p.share_mobile_phone_with(people(:peter))
    # family = false, person = true, peter should see
    f.update_attribute :share_mobile_phone, false
    p.update_attribute :share_mobile_phone, true
    assert p.share_mobile_phone_with(people(:peter))
    # family = true, person = nil, peter should see
    f.update_attribute :share_mobile_phone, true
    p.update_attribute :share_mobile_phone, nil
    assert Person.find(people(:jennie).id).share_mobile_phone_with(people(:peter))
    # family = false, person = nil, peter should not see
    f.update_attribute :share_mobile_phone, false
    p.update_attribute :share_mobile_phone, nil
    assert !Person.find(people(:jennie).id).share_mobile_phone_with(people(:peter))
  end
  
  def test_update
    tim = {
      :person => partial_fixture('people', 'tim', %w(first_name last_name suffix gender mobile_phone work_phone fax birthday anniversary)),
      :family => partial_fixture('families', 'morgan', %w(name last_name home_phone address1 address2 city state zip))
    }

    (tim_change_first_name = tim.clone)[:person][:first_name] = 'Timothy'
    update = Update.create_from_params(tim_change_first_name, people(:tim))
    assert_equal 'Timothy', update.first_name
    assert_equal '04/28/1981', update.birthday.strftime('%m/%d/%Y')
    assert_equal '08/11/2001', update.anniversary.strftime('%m/%d/%Y')

    (tim_change_birthday = tim.clone)[:person][:birthday] = '06/24/1980'
    update = Update.create_from_params(tim_change_birthday, people(:tim))
    assert_equal '06/24/1980', update.birthday.strftime('%m/%d/%Y')
    assert_equal '08/11/2001', update.anniversary.strftime('%m/%d/%Y')
    
    (tim_remove_anniversary = tim.clone)[:person][:anniversary] = ''
    update = Update.create_from_params(tim_remove_anniversary, people(:tim))
    assert_equal '06/24/1980', update.birthday.strftime('%m/%d/%Y')
    assert_equal '01/01/1800', update.anniversary.strftime('%m/%d/%Y')
  end
  
  private
  
    def partial_fixture(table, name, valid_attributes)
      YAML::load(File.open(File.join(RAILS_ROOT, "test/fixtures/#{table}.yml")))[name].delete_if do |key, val|
        !valid_attributes.include? key
      end
    end
end
