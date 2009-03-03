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
    assert_equal "has an incorrect format (are you missing 'http://' at the beginning?)", p.errors[:website]
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
  
  should "share information with people and group members properly" do
    people(:peter).update_attributes! :share_mobile_phone => false
    assert !people(:peter).share_mobile_phone_with?(people(:jeremy))
    people(:peter).update_attributes! :share_mobile_phone => true
    assert people(:peter).share_mobile_phone_with?(people(:jeremy))
    people(:peter).update_attributes! :share_mobile_phone => false
    memberships(:peter_in_college_group).update_attributes! :share_mobile_phone => true
    assert people(:peter).share_mobile_phone_with?(people(:jeremy))
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
  
  should "know when a birthday is coming up" do
    people(:tim).update_attributes!(:birthday => Time.now + 5.days - 27.years)
    assert people(:tim).reload.birthday_soon?
    people(:tim).update_attributes!(:birthday => Time.now - 27.years + (BIRTHDAY_SOON_DAYS + 1).days)
    assert !people(:tim).reload.birthday_soon?
  end
  
  should "return a random selection of sidebar group people" do
    @group = Group.forge(:category => 'Small Groups')
    15.times { @group.memberships.create!(:person => Person.forge) }
    @person = @group.people.last
    assert_equal 14, @person.sidebar_group_people.length # does not include self
    first_time  = @person.random_sidebar_group_people(10)
    second_time = @person.random_sidebar_group_people(10)
    assert_not_equal first_time, second_time
    assert_equal 10, first_time.length
    assert_equal 10, second_time.length
  end
  
  should "not tz convert a birthday or anniversary" do
    Time.zone = 'Central Time (US & Canada)'
    people(:tim).update_attributes!(:birthday => '4/28/1981')
    assert_equal '04/28/1981 00:00:00', people(:tim).reload.birthday.strftime('%m/%d/%Y %H:%M:%S')
    people(:tim).update_attributes!(:anniversary => '8/11/2001')
    assert_equal '08/11/2001 00:00:00', people(:tim).reload.anniversary.strftime('%m/%d/%Y %H:%M:%S')
  end
  
  should "handle birthdays before 1970" do
    people(:tim).update_attributes!(:birthday => '1/1/1920')
    assert_equal '01/01/1920', people(:tim).reload.birthday.strftime('%m/%d/%Y')
  end
  
  should "only store digits for phone numbers" do
    people(:tim).update_attributes!(:mobile_phone => '(123) 456-7890')
    assert_equal '1234567890', people(:tim).reload.mobile_phone
  end
  
  should "update custom_fields with a hash" do
    people(:tim).custom_fields = {'0' => 'first', '2' => 'third'}
    assert_equal ['first', nil, 'third'], people(:tim).custom_fields
  end
  
  should "convert dates saved in custom_fields" do
    Setting.set(1, 'Features', 'Custom Person Fields', ['Text', 'A Date'].join("\n"))
    people(:tim).custom_fields = {'0' => 'first', '1' => 'March 1, 2012'}
    assert_equal ['first', Date.new(2012, 3, 1)], people(:tim).custom_fields
    Setting.set(1, 'Features', 'Custom Person Fields', '')
  end
  
  should "update custom_fields with an array" do
    people(:tim).custom_fields = ['first', nil, 'third']
    assert_equal ['first', nil, 'third'], people(:tim).custom_fields
  end
  
  should "not overwrite existing custom_fields accidentally" do
    people(:tim).custom_fields = {'0' => 'first', '2' => 'third'}
    people(:tim).custom_fields = {'1' => 'second'}
    assert_equal ['first', 'second', 'third'], people(:tim).custom_fields
  end
  
  should "create an update with custom_fields" do
    Person.logged_in = people(:jeremy)
    people(:jeremy).update_from_params(
      :person => {
        :first_name => 'Jeremy',
        :custom_fields => {'0' => 'first', '2' => 'third'}
      }
    )
    people(:jeremy).updates.reload
    assert_equal ['first', nil, 'third'], people(:jeremy).updates.last.custom_fields
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
