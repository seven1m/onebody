require_relative '../test_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL == 'support@example.com'

class PersonTest < ActiveSupport::TestCase

  context 'Formats' do

    BAD_EMAIL_ADDRESSES  = ['bad address@example.com', 'bad~address@example.com', 'baddaddress@example.123']
    GOOD_EMAIL_ADDRESSES = ['bob@example.com', 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com']
    BAD_WEB_ADDRESSES    = ['www.badaddress.com', 'ftp://badaddress.org', "javascript://void(alert('do evil stuff'))"]
    GOOD_WEB_ADDRESSES   = ['http://www.goodwebsite.org', 'http://goodwebsite.com/a/path?some=args']

    setup { @person = FactoryGirl.create(:person) }

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
      @person = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person, family: @person.family, email: @person.email)
      assert @person2.valid?
    end

    should 'not allow people in different families to have the same email address' do
      @person = FactoryGirl.create(:person, email: 'john@example.com')
      assert_raise(ActiveRecord::RecordInvalid) { FactoryGirl.create(:person, email: 'john@example.com') }
    end

  end

  context 'Group Membership' do

    setup do
      @group = FactoryGirl.create(:group)
      @person, @person2 = FactoryGirl.create_list(:person, 2)
    end

    should 'know of basic group memberships' do
      @group.memberships.create! person: @person
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
      @child = FactoryGirl.create(:person, family: @person.family, child: true)
      @group.memberships.create! person: @child
      @parent_group = FactoryGirl.create(:group, parents_of: @group.id)
      @parent_group.update_memberships
      assert @person.member_of?(@parent_group)
      assert !@person2.member_of?(@parent_group)
    end

    should 'know about parent_of group memberships via linked group membership' do
      @child = FactoryGirl.create(:person, family: @person.family, child: true)
      @group.link_code = 'B345'
      @group.save!
      @child.classes = 'A123,B345,C567'
      @child.save!
      @group.update_memberships
      @parent_group = FactoryGirl.create(:group, parents_of: @group.id)
      @parent_group.update_memberships
      assert @person.member_of?(@parent_group)
      assert !@person2.member_of?(@parent_group)
    end

  end

  should "mark email_changed when email address changes" do
    @person = FactoryGirl.create(:person)
    @person.email = 'newaddress@example.com'
    assert !@person.email_changed?
    @person.save
    assert @person.email_changed?
  end

  should 'lowercase email' do
    @person = FactoryGirl.build(:person)
    @person.email = 'TEST@example.COM'
    assert_equal 'test@example.com', @person.email
  end

  should 'lowercase alternate_email' do
    @person = FactoryGirl.build(:person)
    @person.alternate_email = 'TEST@example.COM'
    assert_equal 'test@example.com', @person.alternate_email
  end

  should "generate a custom directory pdf" do
    @person = FactoryGirl.create(:person)
    assert_match /PDF\-1\.3/, @person.generate_directory_pdf.to_s[0..100]
  end

  should "know when a birthday is coming up" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(birthday: Time.now + 5.days - 27.years)
    assert @person.reload.birthday_soon?
    @person.update_attributes!(birthday: Time.now - 27.years + (BIRTHDAY_SOON_DAYS + 1).days)
    assert !@person.reload.birthday_soon?
  end

  should "not tz convert a birthday" do
    @person = FactoryGirl.create(:person)
    Time.zone = 'Central Time (US & Canada)'
    @person.update_attributes!(birthday: '4/28/1981')
    assert_equal '04/28/1981 00:00:00', @person.reload.birthday.strftime('%m/%d/%Y %H:%M:%S')
  end

  should "not tz convert an anniversary" do
    @person = FactoryGirl.create(:person)
    Time.zone = 'Central Time (US & Canada)'
    @person.update_attributes!(anniversary: '8/11/2001')
    assert_equal '08/11/2001 00:00:00', @person.reload.anniversary.strftime('%m/%d/%Y %H:%M:%S')
  end

  should "parse birthday string by locale" do
    @person = FactoryGirl.create(:person)
    Setting.set(Site.current.id, 'Formats', 'Date', '%d/%m/%Y')
    @person.birthday = '29/4/1981'
    assert_equal Date.new(1981, 4, 29), @person.birthday
    Setting.set(Site.current.id, 'Formats', 'Date', '%m/%d/%Y')
    @person.birthday = '4/28/1981'
    assert_equal Date.new(1981, 4, 28), @person.birthday
  end

  should "parse anniversary string by locale" do
    @person = FactoryGirl.create(:person)
    Setting.set(Site.current.id, 'Formats', 'Date', '%d/%m/%Y')
    @person.anniversary = '12/8/1981'
    assert_equal Date.new(1981, 8, 12), @person.anniversary
    Setting.set(Site.current.id, 'Formats', 'Date', '%m/%d/%Y')
    @person.anniversary = '8/11/1981'
    assert_equal Date.new(1981, 8, 11), @person.anniversary
  end

  should "handle birthdays before 1970" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(birthday: '1/1/1920')
    assert_equal '01/01/1920', @person.reload.birthday.strftime('%m/%d/%Y')
  end

  should "only store digits for phone numbers" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(mobile_phone: '(123) 456-7890')
    assert_equal '1234567890', @person.reload.mobile_phone
  end

  context 'Custom Fields' do

    setup { @person = FactoryGirl.create(:person) }

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

  end

  context 'Stream' do

    setup do
      @person = FactoryGirl.create(:person)
      @friend = FactoryGirl.create(:person, first_name: 'James', email: 'james@example.com')
      @pic = FactoryGirl.create(:picture, person: @person)
    end

    should 'eager load commenters on stream items' do
      @pic.comments.create!(person: @friend)
      stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Album', @pic.album_id)
      received = @person.shared_stream_items
      assert_equal 1, received.length
      assert_equal stream_item.id, received.first.id
      assert_equal @friend.id, received.first.context['comments'].first['person'].id
    end

    should 'be show thumbnail for eager loaded commenters' do
      @friend.photo = File.open(Rails.root.join('test/fixtures/files/image.jpg'))
      @friend.save
      @pic.comments.create!(person: @friend)
      received = @person.shared_stream_items.first
      assert_match %r{#{@person.photo_fingerprint}\.jpg}, received.context['comments'].first['person'].photo.url
    end

  end

  context 'Child' do
    should "guess child upon initialization" do
      @family = FactoryGirl.create(:family)
      FactoryGirl.create_list(:person, 2, family: @family)
      @child = @family.people.new
      assert_equal true, @child.child?
    end

    should "sets child=nil when birthday is set" do
      @person = FactoryGirl.build(:person, child: false)
      @person.birthday = 1.year.ago
      assert_nil @person.child
    end

    should "not allow child and birthday to both be unspecified" do
      @person = FactoryGirl.create(:person)
      @person.birthday = nil
      @person.child = nil
      @person.save
      assert @person.errors[:child]
    end
  end

  should "guess last_name upon initialization" do
    @family = FactoryGirl.create(:family, last_name: 'Smith')
    @person = @family.people.new
    assert_equal 'Smith', @person.last_name
  end

  should "select a proper sequence within the family if none is specified" do
    @person = FactoryGirl.create(:person)
    @person2 = FactoryGirl.create(:person, family: @person.family)
    assert_equal @person.family_id, @person2.family_id
    assert_equal 1, @person.sequence
    assert_equal 2, @person2.sequence
    @person2.sequence = nil
    @person2.save
    assert_equal 2, @person2.sequence
  end

  should "know if it is a super admin" do
    @person1 = FactoryGirl.create(:person)
    assert !@person1.admin?
    assert !@person1.super_admin?
    @person2 = FactoryGirl.create(:person, admin: Admin.create)
    assert @person2.admin?
    assert !@person2.super_admin?
    @person3 = FactoryGirl.create(:person, admin: Admin.create(super_admin: true))
    assert @person3.admin?
    assert @person3.super_admin?
    @person4 = FactoryGirl.create(:person, email: 'support@example.com')
    assert @person4.admin?
    assert @person4.super_admin?
  end

  should "properly translate validation errors" do
    @person = FactoryGirl.create(:person)
    assert !@person.update_attributes(website: 'bad/address')
    assert_equal [I18n.t('activerecord.errors.models.person.attributes.website.invalid')],
      @person.errors.full_messages
  end

  context '#authenticate' do
    context 'right password' do
      setup do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate(@person.email, 'secret')
      end

      should 'return false' do
        assert_equal @person, @authenticated
      end
    end

    context 'wrong password' do
      setup do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate(@person.email, 'bad-password')
      end

      should 'return false' do
        assert_equal false, @authenticated
      end
    end

    context 'user with mixed case email' do
      setup do
        @person = FactoryGirl.create(:person, email: 'MIXED_case@example.com', password: 'secret')
        @authenticated = Person.authenticate('mixed_CASE@example.com', 'secret')
      end

      should 'authenticate properly' do
        assert_equal @person, @authenticated
      end
    end

    context 'wrong email' do
      setup do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate('wrong-email@example.com', 'secret')
      end

      should 'return false' do
        assert_nil @authenticated
      end
    end

    context 'user with legacy password' do
      setup do
        @person = FactoryGirl.create(:person,
          email:              'bill@example.com',
          encrypted_password: 'ec30317d2d9133b897cfac6718680f60a0110cec',
          salt:               '0vrXxHlAjAY1w1frfCBYwcbHUHeOBcHlSn8VVXeSg9tWZfjYbq'
        )
        @authenticated = Person.authenticate('bill@example.com', 'secret')
      end

      should 'return the authenticated person' do
        assert_equal @person, @authenticated
      end

      should 'change to BCrypt password hash' do
        assert_not_nil @person.reload.password_hash
        assert_not_nil @person.password_salt
      end

      should 'remove old password hash' do
        assert_nil @person.reload.encrypted_password
        assert_nil @person.salt
      end
    end
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
