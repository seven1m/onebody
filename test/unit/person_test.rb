require File.dirname(__FILE__) + '/../test_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL == 'support@example.com'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :families

  context 'Formats' do

    BAD_EMAIL_ADDRESSES  = ['bad address@example.com', 'bad~address@example.com', 'baddaddress@example.123']
    GOOD_EMAIL_ADDRESSES = ['bob@example.com', 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com']
    BAD_WEB_ADDRESSES    = ['www.badaddress.com', 'ftp://badaddress.org', "javascript://void(alert('do evil stuff'))"]
    GOOD_WEB_ADDRESSES   = ['http://www.goodwebsite.org', 'http://goodwebsite.com/a/path?some=args']

    setup { @person = Person.forge }

    BAD_EMAIL_ADDRESSES.each do |address|
      should_not allow_value(address).for(:email)
    end

    GOOD_EMAIL_ADDRESSES.each do |address|
      should allow_value(address).for(:email)
    end

    BAD_EMAIL_ADDRESSES.each do |address|
      should_not allow_value(address).for(:business_email)
    end

    GOOD_EMAIL_ADDRESSES.each do |address|
      should allow_value(address).for(:business_email)
    end

    BAD_EMAIL_ADDRESSES.each do |address|
      should_not allow_value(address).for(:alternate_email)
    end

    GOOD_EMAIL_ADDRESSES.each do |address|
      should allow_value(address).for(:alternate_email)
    end

    BAD_WEB_ADDRESSES.each do |address|
      should_not allow_value(address).for(:website)
    end

    GOOD_WEB_ADDRESSES.each do |address|
      should allow_value(address).for(:website)
    end

    BAD_WEB_ADDRESSES.each do |address|
      should_not allow_value(address).for(:business_website)
    end

    GOOD_WEB_ADDRESSES.each do |address|
      should allow_value(address).for(:business_website)
    end

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
      assert @person2.errors[:email]
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
      @group.link_code = 'B345'
      @group.save!
      @person.classes = 'A123,B345,C567'
      @person.save!
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
      @group.link_code = 'B345'
      @group.save!
      @child.classes = 'A123,B345,C567'
      @child.save!
      @group.update_memberships
      @parent_group = Group.forge(:parents_of => @group.id)
      @parent_group.update_memberships
      assert @person.member_of?(@parent_group)
      assert !@person2.member_of?(@parent_group)
    end

  end

  context 'Updates' do

    context 'Dates' do

      setup do
        @tim = {
          'person' => partial_fixture('people', 'tim', %w(first_name last_name suffix gender mobile_phone work_phone fax birthday anniversary)),
          'family' => partial_fixture('families', 'morgan', %w(name last_name home_phone address1 address2 city state zip))
        }
      end

      should "create an update with no dates changed" do
        @tim['person']['first_name'] = 'Timothy'
        update = Update.create_from_params(@tim, people(:tim))
        assert_equal 'Timothy', update.first_name
        assert_equal nil, update.birthday
        assert_equal nil, update.anniversary
      end

      should "create an update with one date changed" do
        @tim['person']['birthday'] = '06/24/1980'
        update = Update.create_from_params(@tim, people(:tim))
        assert_equal '06/24/1980', update.birthday.strftime('%m/%d/%Y')
        assert_equal nil, update.anniversary
      end

      should "create an update with a date removed" do
        @tim['person']['anniversary'] = ''
        update = Update.create_from_params(@tim, people(:tim))
        assert_equal nil, update.birthday
        assert_equal '01/01/1800', update.anniversary.strftime('%m/%d/%Y')
      end

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

  context 'Stream' do

    setup do
      @person = Person.forge
      @friend = Person.forge
      StreamItem.delete_all # clear fixtures
      @pic = @person.forge(:pictures)
    end

    should 'eager load commenters on stream items' do
      @pic.comments.create!(:person => @friend)
      stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Album', @pic.album_id)
      received = @person.shared_stream_items
      assert_equal 1, received.length
      assert_equal stream_item.id, received.first.id
      assert_equal @friend.id, received.first.context['comments'].first['person'].id
    end

    should 'be show thumbnail for eager loaded commenters' do
      @friend.photo = File.open(Rails.root.join('test/fixtures/files/image.jpg'))
      @friend.save
      @pic.comments.create!(:person => @friend)
      received = @person.shared_stream_items.first
      assert_match %r{#{@person.photo_fingerprint}\.jpg}, received.context['comments'].first['person'].photo.url
    end

  end

  should "not allow child and birthday to both be unspecified" do
    @person = Person.forge
    @person.birthday = nil
    @person.child = nil
    @person.save
    assert @person.errors[:child]
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

  context 'Donor Tools' do

    setup do
      @person = Person.forge
    end

    should "update synced_to_donortools when certain attributes change" do
      @person.update_attribute(:synced_to_donortools, true)
      assert @person.synced_to_donortools
      @person.update_attribute(:first_name, 'Foo')
      assert !@person.synced_to_donortools
    end

    should "not update synced_to_donortools every time" do
      @person.update_attribute(:synced_to_donortools, true)
      assert @person.synced_to_donortools
      @person.update_attribute(:activities, 'Foo')
      assert @person.synced_to_donortools
    end

    should "update synced_to_donortools when certain family attributes change" do
      @person2 = Person.forge
      @person2.family = @person.family
      @person.update_attribute(:synced_to_donortools, true)
      @person2.update_attribute(:synced_to_donortools, true)
      assert @person.synced_to_donortools?
      assert @person2.synced_to_donortools?
      @person.family.update_attribute(:home_phone, '9181234567')
      assert !@person.reload.synced_to_donortools?
      assert !@person2.reload.synced_to_donortools?
    end

  end

  should "know if it is a super admin" do
    @person1 = Person.forge
    assert !@person1.admin?
    assert !@person1.super_admin?
    @person2 = Person.forge(:admin => Admin.create)
    assert @person2.admin?
    assert !@person2.super_admin?
    @person3 = Person.forge(:admin => Admin.create(:super_admin => true))
    assert @person3.admin?
    assert @person3.super_admin?
    @person4 = Person.forge(:email => 'support@example.com')
    assert @person4.admin?
    assert @person4.super_admin?
  end

  should "properly translate validation errors" do
    @person = Person.forge
    assert !@person.update_attributes(:website => 'bad/address')
    assert_equal [I18n.t('activerecord.errors.models.person.attributes.website.invalid')],
      @person.errors.full_messages
  end

  private

    def partial_fixture(table, name, valid_attributes)
      YAML::load(File.open(Rails.root.join("test/fixtures/#{table}.yml")))[name].tap do |fixture|
        fixture.delete_if { |key, val| !valid_attributes.include? key }
        fixture.each do |key, val|
          fixture[key] = val.to_s
        end
      end
    end
end
