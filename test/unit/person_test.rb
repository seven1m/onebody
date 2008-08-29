require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase
  fixtures :people, :families
  
  should "know which groups the person belongs to" do
    Group.find(:all).each do |group|
      group.people.each do |person|
        assert person.member_of?(group)
      end
    end
  end
  
  should "not allow someone outside the family to share the same email address" do
    # tim already has email address
    p = people(:peter)
    p.email = people(:tim).email
    p.save
    assert !p.valid?
    assert_equal 'already taken by someone else.', p.errors[:email]
  end
  
  should "validate format of email address" do
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
    assert !p.valid?
    assert_equal 'not a valid email address.', p.errors[:email]
  end
  
  should "validate format of website" do
    Person.logged_in = people(:peter)
    # good
    p = people(:peter)
    p.website = 'http://goodwebsite.com/a/path?some=args'
    p.save
    assert_nil p.errors[:website]
    # bad
    p.website = "javascript://void(alert('do evil stuff'))"
    p.save
    assert !p.valid?
    assert_equal 'is invalid', p.errors[:website]
  end
  
  should "inherit attribute sharing from family" do
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
  
  should "create an update" do
    tim = {
      'person' => partial_fixture('people', 'tim', %w(first_name last_name suffix gender mobile_phone work_phone fax birthday anniversary)),
      'family' => partial_fixture('families', 'morgan', %w(name last_name home_phone address1 address2 city state zip))
    }

    (tim_change_first_name = tim.clone)['person']['first_name'] = 'Timothy'
    update = Update.create_from_params(tim_change_first_name, people(:tim))
    assert_equal 'Timothy', update.first_name
    assert_equal '04/28/1981', update.birthday.strftime('%m/%d/%Y')
    assert_equal '08/11/2001', update.anniversary.strftime('%m/%d/%Y')

    (tim_change_birthday = tim.clone)['person']['birthday'] = '06/24/1980'
    update = Update.create_from_params(tim_change_birthday, people(:tim))
    assert_equal '06/24/1980', update.birthday.strftime('%m/%d/%Y')
    assert_equal '08/11/2001', update.anniversary.strftime('%m/%d/%Y')
    
    (tim_remove_anniversary = tim.clone)['person']['anniversary'] = ''
    update = Update.create_from_params(tim_remove_anniversary, people(:tim))
    assert_equal '06/24/1980', update.birthday.strftime('%m/%d/%Y')
    assert_equal nil,          update.anniversary
  end
  
  should "mark email_changed when email address changes" do
    Person.logged_in = people(:tim)
    people(:tim).email = 'change@example.com'
    assert !people(:tim).email_changed?
    people(:tim).save
    assert people(:tim).email_changed?
  end
  
  should "generate a custom directory pdf" do
    assert_match /PDF\-1\.3/, people(:tim).generate_directory_pdf.to_s[0..100]
  end
  
  should "generate a unique hash of values based on specified attributes" do
    was = people(:tim).values_hash(:first_name, :last_name)
    assert_equal was, people(:tim).reload.values_hash(:first_name, :last_name) # hasn't changed
    people(:tim).update_attributes!(:first_name => 'Timothy')
    assert_not_equal was, people(:tim).reload.values_hash(:first_name, :last_name) # changed
  end
  
  should "consistently hash datetime values" do
    assert_equal \
      Digest::SHA1.hexdigest(people(:tim).birthday.strftime('%Y/%m/%d %H:%M')),
      people(:tim).values_hash(:birthday)
  end
  
  private
  
    def partial_fixture(table, name, valid_attributes)
      returning YAML::load(File.open(File.join(RAILS_ROOT, "test/fixtures/#{table}.yml")))[name] do |fixture|
        fixture.delete_if { |key, val| !valid_attributes.include? key }
        fixture.each do |key, val|
          fixture[key] = val.to_s
        end
      end
    end
end
