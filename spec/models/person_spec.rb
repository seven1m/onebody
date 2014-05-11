require_relative '../spec_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL == 'support@example.com'

describe Person do

  describe 'Formats' do

    BAD_EMAIL_ADDRESSES  = ['bad address@example.com', 'bad~address@example.com', 'baddaddress@example.123']
    GOOD_EMAIL_ADDRESSES = ['bob@example.com', 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com']
    BAD_WEB_ADDRESSES    = ['www.badaddress.com', 'ftp://badaddress.org', "javascript://void(alert('do evil stuff'))"]
    GOOD_WEB_ADDRESSES   = ['http://www.goodwebsite.org', 'http://goodwebsite.com/a/path?some=args']

    setup { @person = FactoryGirl.create(:person) }

    it 'should not allow bad email' do
      BAD_EMAIL_ADDRESSES.each do |address|
        should_not allow_value(address).for(:email)
      end
    end

    it 'should allow good email' do
      GOOD_EMAIL_ADDRESSES.each do |address|
        should allow_value(address).for(:email)
      end
    end

    it 'should not allow bad business_email' do
      BAD_EMAIL_ADDRESSES.each do |address|
        should_not allow_value(address).for(:business_email)
      end
    end

    it 'should allow good business_email' do
      GOOD_EMAIL_ADDRESSES.each do |address|
        should allow_value(address).for(:business_email)
      end
    end

    it 'should not allow bad alternate_email' do
      BAD_EMAIL_ADDRESSES.each do |address|
        should_not allow_value(address).for(:alternate_email)
      end
    end

    it 'should allow good alternate_email' do
      GOOD_EMAIL_ADDRESSES.each do |address|
        should allow_value(address).for(:alternate_email)
      end
    end

    it 'should not allow bad website' do
      BAD_WEB_ADDRESSES.each do |address|
        should_not allow_value(address).for(:website)
      end
    end

    it 'should allow good website' do
      GOOD_WEB_ADDRESSES.each do |address|
        should allow_value(address).for(:website)
      end
    end

    it 'should not allow bad business_website' do
      BAD_WEB_ADDRESSES.each do |address|
        should_not allow_value(address).for(:business_website)
      end
    end

    it 'should allow good business_website' do
      GOOD_WEB_ADDRESSES.each do |address|
        should allow_value(address).for(:business_website)
      end
    end
  end

  context 'Email Address Sharing' do

    it 'should allow people in the same family to have the same email address' do
      @person = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person, family: @person.family, email: @person.email)
      expect(@person2).to be_valid
    end

    it 'should not allow people in different families to have the same email address' do
      @person = FactoryGirl.create(:person, email: 'john@example.com')
      expect {
        FactoryGirl.create(:person, email: 'john@example.com')
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end

  context 'Group Membership' do

    before do
      @group = FactoryGirl.create(:group)
      @person, @person2 = FactoryGirl.create_list(:person, 2)
    end

    it 'should know of basic group memberships' do
      @group.memberships.create! person: @person
      expect(@person.member_of?(@group)).to be
      expect(@person2.member_of?(@group)).not_to be
    end

    it 'should know about linked group memberships' do
      @group.link_code = 'B345'
      @group.save!
      @person.classes = 'A123,B345,C567'
      @person.save!
      @group.update_memberships
      expect(@person.member_of?(@group)).to be
      expect(@person2.member_of?(@group)).not_to be
    end

    it 'should know about parent_of group memberships via basic group membership' do
      @child = FactoryGirl.create(:person, family: @person.family, child: true)
      @group.memberships.create! person: @child
      @parent_group = FactoryGirl.create(:group, parents_of: @group.id)
      @parent_group.update_memberships
      expect(@person.member_of?(@parent_group)).to be
      expect(@person2.member_of?(@parent_group)).not_to be
    end

    it 'should know about parent_of group memberships via linked group membership' do
      @child = FactoryGirl.create(:person, family: @person.family, child: true)
      @group.link_code = 'B345'
      @group.save!
      @child.classes = 'A123,B345,C567'
      @child.save!
      @group.update_memberships
      @parent_group = FactoryGirl.create(:group, parents_of: @group.id)
      @parent_group.update_memberships
      expect(@person.member_of?(@parent_group)).to be
      expect(@person2.member_of?(@parent_group)).not_to be
    end

  end

  it "should mark email_changed when email address changes" do
    @person = FactoryGirl.create(:person)
    @person.email = 'newaddress@example.com'
    expect(@person).to_not be_email_changed
    @person.save
    expect(@person).to be_email_changed
  end

  it 'should lowercase email' do
    @person = FactoryGirl.build(:person)
    @person.email = 'TEST@example.COM'
    expect(@person.email).to eq("test@example.com")
  end

  it 'should lowercase alternate_email' do
    @person = FactoryGirl.build(:person)
    @person.alternate_email = 'TEST@example.COM'
    expect(@person.alternate_email).to eq("test@example.com")
  end

  it "should generate a custom directory pdf" do
    @person = FactoryGirl.create(:person)
    expect(@person.generate_directory_pdf.to_s[0..100]).to match(/PDF\-1\.3/)
  end

  it "should know when a birthday is coming up" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(birthday: Time.now + 5.days - 27.years)
    expect(@person.reload).to be_birthday_soon
    @person.update_attributes!(birthday: Time.now - 27.years + (BIRTHDAY_SOON_DAYS + 1).days)
    expect(@person.reload).to_not be_birthday_soon
  end

  it "should not tz convert a birthday" do
    @person = FactoryGirl.create(:person)
    Time.zone = 'Central Time (US & Canada)'
    @person.update_attributes!(birthday: '4/28/1981')
    expect(@person.reload.birthday.strftime("%m/%d/%Y %H:%M:%S")).to eq("04/28/1981 00:00:00")
  end

  it "should not tz convert an anniversary" do
    @person = FactoryGirl.create(:person)
    Time.zone = 'Central Time (US & Canada)'
    @person.update_attributes!(anniversary: '8/11/2001')
    expect(@person.reload.anniversary.strftime("%m/%d/%Y %H:%M:%S")).to eq("08/11/2001 00:00:00")
  end

  it "should parse birthday string by locale" do
    @person = FactoryGirl.create(:person)
    Setting.set(Site.current.id, 'Formats', 'Date', '%d/%m/%Y')
    @person.birthday = '29/4/1981'
    expect(@person.birthday).to eq(Date.new(1981, 4, 29))
    Setting.set(Site.current.id, 'Formats', 'Date', '%m/%d/%Y')
    @person.birthday = '4/28/1981'
    expect(@person.birthday).to eq(Date.new(1981, 4, 28))
  end

  it "should parse anniversary string by locale" do
    @person = FactoryGirl.create(:person)
    Setting.set(Site.current.id, 'Formats', 'Date', '%d/%m/%Y')
    @person.anniversary = '12/8/1981'
    expect(@person.anniversary).to eq(Date.new(1981, 8, 12))
    Setting.set(Site.current.id, 'Formats', 'Date', '%m/%d/%Y')
    @person.anniversary = '8/11/1981'
    expect(@person.anniversary).to eq(Date.new(1981, 8, 11))
  end

  it "should handle birthdays before 1970" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(birthday: '1/1/1920')
    expect(@person.reload.birthday.strftime("%m/%d/%Y")).to eq("01/01/1920")
  end

  it "should only store digits for phone numbers" do
    @person = FactoryGirl.create(:person)
    @person.update_attributes!(mobile_phone: '(123) 456-7890')
    expect(@person.reload.mobile_phone).to eq("1234567890")
  end

  context 'Custom Fields' do

    before { @person = FactoryGirl.create(:person) }

    it "should update custom_fields with a hash" do
      @person.custom_fields = {'0' => 'first', '2' => 'third'}
      expect(@person.custom_fields).to eq(["first", nil, "third"])
    end

    it "should convert dates saved in custom_fields" do
      Setting.set(1, 'Features', 'Custom Person Fields', ['Text', 'A Date'].join("\n"))
      @person.custom_fields = {'0' => 'first', '1' => 'March 1, 2012'}
      expect(@person.custom_fields).to eq(["first", Date.new(2012, 3, 1)])
      Setting.set(1, 'Features', 'Custom Person Fields', '')
    end

    it "should update custom_fields with an array" do
      @person.custom_fields = ['first', nil, 'third']
      expect(@person.custom_fields).to eq(["first", nil, "third"])
    end

    it "should not overwrite existing custom_fields accidentally" do
      @person.custom_fields = {'0' => 'first', '2' => 'third'}
      @person.custom_fields = {'1' => 'second'}
      expect(@person.custom_fields).to eq(["first", "second", "third"])
    end

  end

  describe 'Stream' do

    before do
      @person = FactoryGirl.create(:person)
      @friend = FactoryGirl.create(:person, first_name: 'James', email: 'james@example.com')
      @pic = FactoryGirl.create(:picture, person: @person)
    end

    it 'should eager load commenters on stream items' do
      @pic.comments.create!(person: @friend)
      stream_item = StreamItem.where(streamable_type: "Album", streamable_id: @pic.album_id).first
      received = @person.shared_stream_items
      expect(received.length).to eq(1)
      expect(received.first.id).to eq(stream_item.id)
      expect(received.first.context["comments"].first["person"].id).to eq(@friend.id)
    end

    it 'should be show thumbnail for eager loaded commenters' do
      @friend.photo = File.open(Rails.root.join('spec/fixtures/files/image.jpg'))
      @friend.save
      @pic.comments.create!(person: @friend)
      received = @person.shared_stream_items.first
      expect(received.context["comments"].first["person"].photo.url).to match(/#{@person.photo_fingerprint}\.jpg/)
    end

  end

  describe 'Child' do
    it "should guess child upon initialization" do
      @family = FactoryGirl.create(:family)
      FactoryGirl.create_list(:person, 2, family: @family)
      @child = @family.people.new
      expect(@child.child?).to eq(true)
    end

    it "should sets child=nil when birthday is set" do
      @person = FactoryGirl.build(:person, child: false)
      @person.birthday = 1.year.ago
      expect(@person.child).to be_nil
    end

    it "should not allow child and birthday to both be unspecified" do
      @person = FactoryGirl.create(:person)
      @person.birthday = nil
      @person.child = nil
      @person.save
      expect(@person.errors[:child]).to be
    end
  end

  it "should guess last_name upon initialization" do
    @family = FactoryGirl.create(:family, last_name: 'Smith')
    @person = @family.people.new
    expect(@person.last_name).to eq("Smith")
  end

  it "should select a proper sequence within the family if none is specified" do
    @person = FactoryGirl.create(:person)
    @person2 = FactoryGirl.create(:person, family: @person.family)
    expect(@person2.family_id).to eq(@person.family_id)
    expect(@person.sequence).to eq(1)
    expect(@person2.sequence).to eq(2)
    @person2.sequence = nil
    @person2.save
    expect(@person2.sequence).to eq(2)
  end

  it "should know if it is a super admin" do
    @person1 = FactoryGirl.create(:person)
    expect(@person1).to_not be_admin
    expect(@person1).to_not be_super_admin
    @person2 = FactoryGirl.create(:person, admin: Admin.create)
    expect(@person2).to be_admin
    expect(@person2).to_not be_super_admin
    @person3 = FactoryGirl.create(:person, admin: Admin.create(super_admin: true))
    expect(@person3).to be_admin
    expect(@person3).to be_super_admin
    @person4 = FactoryGirl.create(:person, email: 'support@example.com')
    expect(@person4).to be_admin
    expect(@person4).to be_super_admin
  end

  it "should properly translate validation errors" do
    @person = FactoryGirl.create(:person)
    expect(@person.update_attributes(website: 'bad/address')).not_to be
    expect(@person.errors.full_messages).to eq([I18n.t("activerecord.errors.models.person.attributes.website.invalid")])
  end

  context '#authenticate' do
    context 'right password' do
      before do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate(@person.email, 'secret')
      end

      it 'should return false' do
        expect(@authenticated).to eq(@person)
      end
    end

    context 'wrong password' do
      before do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate(@person.email, 'bad-password')
      end

      it 'should return false' do
        expect(@authenticated).to eq(false)
      end
    end

    context 'user with mixed case email' do
      before do
        @person = FactoryGirl.create(:person, email: 'MIXED_case@example.com', password: 'secret')
        @authenticated = Person.authenticate('mixed_CASE@example.com', 'secret')
      end

      it 'should authenticate properly' do
        expect(@authenticated).to eq(@person)
      end
    end

    context 'wrong email' do
      before do
        @person = FactoryGirl.create(:person, password: 'secret')
        @authenticated = Person.authenticate('wrong-email@example.com', 'secret')
      end

      it 'should return false' do
        expect(@authenticated).to be_nil
      end
    end

    context 'user with legacy password' do
      before do
        @person = FactoryGirl.create(:person,
          email:              'bill@example.com',
          encrypted_password: 'ec30317d2d9133b897cfac6718680f60a0110cec',
          salt:               '0vrXxHlAjAY1w1frfCBYwcbHUHeOBcHlSn8VVXeSg9tWZfjYbq'
        )
        @authenticated = Person.authenticate('bill@example.com', 'secret')
      end

      it 'should return the authenticated person' do
        expect(@authenticated).to eq(@person)
      end

      it 'should change to BCrypt password hash' do
        expect(@person.reload.password_hash).to_not be_nil
        expect(@person.password_salt).to_not be_nil
      end

      it 'should remove old password hash' do
        expect(@person.reload.encrypted_password).to be_nil
        expect(@person.salt).to be_nil
      end
    end
  end

  private

    def partial_fixture(table, name, valid_attributes)
      YAML::load(File.open(Rails.root.join("spec/fixtures/#{table}.yml")))[name].tap do |fixture|
        fixture.delete_if { |key, val| !valid_attributes.include? key }
        fixture.each do |key, val|
          fixture[key] = val.to_s
        end
      end
    end
end
