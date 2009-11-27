require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :families
  
  context 'Formats' do
    
    BAD_EMAIL_ADDRESSES  = ['bad address@example.com', 'bad~address@example.com', 'baddaddress@example.123']
    GOOD_EMAIL_ADDRESSES = ['bob@example.com', 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com']
    BAD_WEB_ADDRESSES    = ['www.badaddress.com', 'ftp://badaddress.org', "javascript://void(alert('do evil stuff'))"]
    GOOD_WEB_ADDRESSES   = ['http://www.goodwebsite.org', 'http://goodwebsite.com/a/path?some=args']
    
    setup { @person = Person.forge }
  
    should_not_allow_values_for :email,            *(BAD_EMAIL_ADDRESSES + [:message => /not formatted correctly/])
    should_allow_values_for     :email,            *GOOD_EMAIL_ADDRESSES
  
    should_not_allow_values_for :business_email,   *(BAD_EMAIL_ADDRESSES + [:message => /not formatted correctly/])
    should_allow_values_for     :business_email,   *GOOD_EMAIL_ADDRESSES
  
    should_not_allow_values_for :alternate_email,  *(BAD_EMAIL_ADDRESSES + [:message => /not formatted correctly/])
    should_allow_values_for     :alternate_email,  *GOOD_EMAIL_ADDRESSES
  
    should_not_allow_values_for :website,          *(BAD_WEB_ADDRESSES   + [:message => /not formatted correctly/])
    should_allow_values_for     :website,          *GOOD_WEB_ADDRESSES
  
    should_not_allow_values_for :business_website, *(BAD_WEB_ADDRESSES   + [:message => /not formatted correctly/])
    should_allow_values_for     :business_website, *GOOD_WEB_ADDRESSES
  
  end
  
  context 'Email Address Sharing' do
    
    should 'allow people in the same family to have the same email address' do
      @person = Person.forge
      @person2 = Person.forge(:family => @person.family, :email => @person.email)
      assert @person2.valid?
    end
    
    should 'not allow people in different families to have the same email address' do
      @person = Person.forge
      @person2 = Person.forge
      @person2.email = @person.email
      @person2.save
      assert @person2.errors.on(:email)
    end
    
  end
  
  context 'Group Membership' do
    
    setup do
      @group = Group.forge
      @person = Person.forge
      @person2 = Person.forge
    end
    
    should 'know of basic group memberships' do
      @group.memberships.create! :person => @person
      assert @person.member_of?(@group)
      assert !@person2.member_of?(@group)
    end
    
    should 'know about linked group memberships' do
      @group.update_attributes!(:link_code => 'B345')
      @person.update_attributes!(:classes => 'A123,B345,C567')
      @group.update_memberships
      assert @person.member_of?(@group)
      assert !@person2.member_of?(@group)
    end
    
    should 'know about parent_of group memberships via basic group membership' do
      @child = Person.forge(:family => @person.family, :child => true)
      @group.memberships.create! :person => @child
      @parent_group = Group.forge(:parents_of => @group.id)
      @parent_group.update_memberships
      assert @person.member_of?(@parent_group)
      assert !@person2.member_of?(@parent_group)
    end
    
    should 'know about parent_of group memberships via linked group membership' do
      @child = Person.forge(:family => @person.family, :child => true)
      @group.update_attributes!(:link_code => 'B345')
      @child.update_attributes!(:classes => 'A123,B345,C567')
      @group.update_memberships
      @parent_group = Group.forge(:parents_of => @group.id)
      @parent_group.update_memberships
      assert @person.member_of?(@parent_group)
      assert !@person2.member_of?(@parent_group)
    end
    
  end

  def assert_viewer_can_see(f, p, g, can_see=true)
    @family.update_attributes!(:share_mobile_phone => f)
    @person.update_attributes!(:share_mobile_phone => p)
    @membership.update_attributes!(:share_mobile_phone => g)
    assert_equal can_see, @person.share_mobile_phone_with(@viewer)
  end
  
  def assert_viewer_cannot_see(f, p, g)
    assert_viewer_can_see(f, p, g, false)
  end
  
  context 'Information Sharing (Privacy)' do
    
    should 'inherit privacy settings from family' do
      @person = Person.forge
      @family = @person.family
      @viewer = Person.forge
      @group = Group.forge
      @group.memberships.create!(:person => @viewer)
      @membership = @group.memberships.create!(:person => @person)
      # test all combinations on a single attribute (share_mobile_phone)
      assert_viewer_cannot_see(true,  false, false)
      assert_viewer_cannot_see(false, false, false)
      assert_viewer_cannot_see(false, nil,   false)
      assert_viewer_can_see(false, true,  false)
      assert_viewer_can_see(true,  nil,   false)
      assert_viewer_can_see(true,  true,  false)
      assert_viewer_can_see(true,  false, true )
      assert_viewer_can_see(false, false, true )
      assert_viewer_can_see(false, nil,   true )
      assert_viewer_can_see(false, true,  true )
      assert_viewer_can_see(true,  nil,   true )
      assert_viewer_can_see(true,  true,  true )
    end
    
  end

  context 'Updates' do

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

    should "update the email address without creating an update" do
      @person = Person.forge
      Person.logged_in = @person
      @person.update_from_params(
        :person => {
          :email => 'somethingelse@example.com'
        }
      )
      @person.updates.reload
      assert_equal 0, @person.updates.count
    end
    
  end
  
  should "mark email_changed when email address changes" do
    @person = Person.forge
    @person.email = 'newaddress@example.com'
    assert !@person.email_changed?
    @person.save
    assert @person.email_changed?
  end
  
  should "generate a custom directory pdf" do
    assert_match /PDF\-1\.3/, Person.forge.generate_directory_pdf.to_s[0..100]
  end
  
  should "know when a birthday is coming up" do
    @person = Person.forge
    @person.update_attributes!(:birthday => Time.now + 5.days - 27.years)
    assert @person.reload.birthday_soon?
    @person.update_attributes!(:birthday => Time.now - 27.years + (BIRTHDAY_SOON_DAYS + 1).days)
    assert !@person.reload.birthday_soon?
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
    @person = Person.forge
    Time.zone = 'Central Time (US & Canada)'
    @person.update_attributes!(:birthday => '4/28/1981')
    assert_equal '04/28/1981 00:00:00', @person.reload.birthday.strftime('%m/%d/%Y %H:%M:%S')
    @person.update_attributes!(:anniversary => '8/11/2001')
    assert_equal '08/11/2001 00:00:00', @person.reload.anniversary.strftime('%m/%d/%Y %H:%M:%S')
  end
  
  should "handle birthdays before 1970" do
    @person = Person.forge
    @person.update_attributes!(:birthday => '1/1/1920')
    assert_equal '01/01/1920', @person.reload.birthday.strftime('%m/%d/%Y')
  end
  
  should "only store digits for phone numbers" do
    @person = Person.forge
    @person.update_attributes!(:mobile_phone => '(123) 456-7890')
    assert_equal '1234567890', @person.reload.mobile_phone
  end
  
  context 'Custom Fields' do
    
    setup { @person = Person.forge }
  
    should "update custom_fields with a hash" do
      @person.custom_fields = {'0' => 'first', '2' => 'third'}
      assert_equal ['first', nil, 'third'], @person.custom_fields
    end
  
    should "convert dates saved in custom_fields" do
      Setting.set(1, 'Features', 'Custom Person Fields', ['Text', 'A Date'].join("\n"))
      @person.custom_fields = {'0' => 'first', '1' => 'March 1, 2012'}
      assert_equal ['first', Date.new(2012, 3, 1)], @person.custom_fields
      Setting.set(1, 'Features', 'Custom Person Fields', '')
    end
  
    should "update custom_fields with an array" do
      @person.custom_fields = ['first', nil, 'third']
      assert_equal ['first', nil, 'third'], @person.custom_fields
    end
  
    should "not overwrite existing custom_fields accidentally" do
      @person.custom_fields = {'0' => 'first', '2' => 'third'}
      @person.custom_fields = {'1' => 'second'}
      assert_equal ['first', 'second', 'third'], @person.custom_fields
    end
  
    should "create an update with custom_fields" do
      Person.logged_in = @person
      @person.update_from_params(
        :person => {
          :first_name => 'Jeremy',
          :custom_fields => {'0' => 'first', '2' => 'third'}
        }
      )
      @person.updates.reload
      assert_equal ['first', nil, 'third'], @person.updates.last.custom_fields
    end
    
  end
  
  should "not allow child and birthday to both be unspecified" do
    @person = Person.forge
    @person.update_attributes(:child => nil, :birthday => nil)
    assert @person.errors.on(:child)
  end
  
  should "select a proper sequence within the family if none is specified" do
    @person = Person.forge
    @person2 = Person.forge(:family => @person.family)
    assert_equal @person.family_id, @person2.family_id
    assert_equal 1, @person.sequence
    assert_equal 2, @person2.sequence
    @person2.sequence = nil
    @person2.save
    assert_equal 2, @person2.sequence
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
