require_relative '../rails_helper'

describe Person do

  describe 'Formats' do

    BAD_EMAIL_ADDRESSES  = ['bad address@example.com', 'bad~address@example.com', 'baddaddress@example.123', 'looksinnocent@example.com\n<script>alert("pwned")</script>']
    GOOD_EMAIL_ADDRESSES = ['bob@example.com', 'abcdefghijklmnopqrstuvwxyz0123456789._%-@abcdefghijklmnopqrstuvwxyz0123456789.-.com', 'admin@newhorizon.church']
    BAD_WEB_ADDRESSES    = ['www.badaddress.com', 'ftp://badaddress.org', "javascript://void(alert('do evil stuff'))"]
    GOOD_WEB_ADDRESSES   = ['http://www.goodwebsite.org', 'http://goodwebsite.com/a/path?some=args']

    before { @person = FactoryGirl.create(:person) }

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

  it 'should allow good facebook_url' do
    should allow_value('https://www.facebook.com/seven1m').for(:facebook_url)
  end

  it 'should not allow bad facebook_url' do
    should_not allow_value('http://notfacebook.com/foo').for(:facebook_url)
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
      expect(@person.member_of?(@group)).to eq(true)
      expect(@person2.member_of?(@group)).to eq(false)
    end

    it 'should know about linked group memberships' do
      @group.membership_mode = 'link_code'
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
      @parent_group = FactoryGirl.create(:group, membership_mode: 'parents_of', parents_of: @group.id)
      @parent_group.update_memberships
      expect(@person.member_of?(@parent_group)).to be
      expect(@person2.member_of?(@parent_group)).not_to be
    end

    it 'should know about parent_of group memberships via linked group membership' do
      @child = FactoryGirl.create(:person, family: @person.family, child: true)
      @group.membership_mode = 'link_code'
      @group.link_code = 'B345'
      @group.save!
      @child.classes = 'A123,B345,C567'
      @child.save!
      @group.update_memberships
      @parent_group = FactoryGirl.create(:group, membership_mode: 'parents_of', parents_of: @group.id)
      @parent_group.update_memberships
      expect(@person.member_of?(@parent_group)).to be
      expect(@person2.member_of?(@parent_group)).not_to be
    end

  end

  it 'should remove @ from twitter username' do
    @person = FactoryGirl.build(:person)
    @person.twitter = "@username"
    @person.save
    expect(@person.twitter).to eq("username")
  end

  it "should not accept twitter username with more than 15 characters" do
    should_not allow_value("fifteencharacter").for(:twitter)
  end

  it "should accept twitter username with at most 15 characters" do
    should allow_value("fifteencharacte").for(:twitter)
  end

  it "should not accept twitter username with symbols" do
    should_not allow_value("foo!").for(:twitter)
  end

  it "should accept twitter username with alphanumeric characters" do
    should allow_value("User_Name123").for(:twitter)
  end

  describe '#email_changed' do
    context 'email address is changed' do
      let(:person) { FactoryGirl.create(:person) }

      before do
        person.email = 'newaddress@example.com'
        expect(person.email_changed).to eq(false)
        person.save
      end

      it 'sets email_changed to true' do
        expect(person.email_changed).to eq(true)
      end

      it 'sends an email' do
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('John Smith Changed Email')
      end
    end

    context 'email address is changed, but the "Send Email Changes To" setting is blank' do
      let(:person) { FactoryGirl.create(:person) }

      before do
        Setting.set(:contact, :send_email_changes_to, '')
        person.email = 'newaddress@example.com'
        person.save
      end

      it 'does not send an email' do
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      after do
        Setting.set(:contact, :send_email_changes_to, 'admin@example.com')
      end
    end

    context 'email address is changed, but dont_mark_email_changed=true' do
      let(:person) { FactoryGirl.create(:person) }

      before do
        person.dont_mark_email_changed = true
        person.email = 'newaddress@example.com'
        person.save
      end

      it 'does not set email_changed' do
        expect(person.email_changed).to eq(false)
      end
    end
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
    @person.birthday = nil
    expect(@person.birthday).to be_nil
    @person.birthday = 'xxxxxx'
    expect(@person).to_not be_valid
    expect(@person.errors[:birthday]).to_not eq([])
  end

  it "should parse anniversary string by locale" do
    @person = FactoryGirl.create(:person)
    Setting.set(Site.current.id, 'Formats', 'Date', '%d/%m/%Y')
    @person.anniversary = '12/8/1981'
    expect(@person.anniversary).to eq(Date.new(1981, 8, 12))
    Setting.set(Site.current.id, 'Formats', 'Date', '%m/%d/%Y')
    @person.anniversary = '8/11/1981'
    expect(@person.anniversary).to eq(Date.new(1981, 8, 11))
    @person.anniversary = nil
    expect(@person.anniversary).to be_nil
    @person.anniversary = 'xxxxxx'
    expect(@person).to_not be_valid
    expect(@person.errors[:anniversary]).to_not eq([])
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

  describe 'Child' do
    it "should guess child upon initialization" do
      @family = FactoryGirl.create(:family)
      FactoryGirl.create_list(:person, 2, family: @family)
      @child = @family.people.new
      expect(@child.child?).to eq(true)
    end

    it "sets child=true when birthday is set and person is < 18 years old" do
      @person = FactoryGirl.build(:person, child: false)
      @person.birthday = 17.years.ago
      @person.valid? # trigger callback
      expect(@person.child).to eq(true)
    end

    it "sets child=false when birthday is set and person is >= 18 years old" do
      @person = FactoryGirl.build(:person, child: true)
      @person.birthday = 18.years.ago
      @person.valid? # trigger callback
      expect(@person.child).to eq(false)
    end

    it "should not allow child and birthday to both be unspecified" do
      @person = FactoryGirl.create(:person)
      @person.birthday = nil
      @person.child = nil
      @person.save
      expect(@person.errors[:child]).to_not be_empty
    end

     it 'should allow child=true while birthday year is 1900' do
      @person = FactoryGirl.create(:person)
      @person.birthday = Date.new(1900, 1, 1)
      @person.child = false
      @person.save
      expect(@person.reload.child).to eq(false)
     end
  end

  it "should guess last_name upon initialization" do
    @family = FactoryGirl.create(:family, last_name: 'Smith')
    @person = @family.people.new
    expect(@person.last_name).to eq("Smith")
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
  end

  it "should properly translate validation errors" do
    @person = FactoryGirl.create(:person)
    expect(@person.update_attributes(website: 'bad/address')).to eq(false)
    expect(@person.errors[:website]).to eq([I18n.t("activerecord.errors.models.person.attributes.website.invalid")])
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

    context 'user with a nickname' do
      before do
        @person = FactoryGirl.create(:person, first_name: 'Saul', last_name: 'Tarsus', alias: 'Paul')
      end

      it 'should have the name Saul Tarsus' do
        expect(@person.name).to eq('Saul Tarsus')
      end

      it 'should have the display with nickname of Saul Tarsus [Paul]' do
        expect(@person.name_and_nick).to eq('Saul Tarsus [Paul]')
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

  describe '.adults_or_have_consent' do
    context 'given several users' do
      let!(:child1) { FactoryGirl.create(:person, child: true) }
      let!(:child2) { FactoryGirl.create(:person, birthday: 1.year.ago) }
      let!(:child3) { FactoryGirl.create(:person, birthday: 1.year.ago, parental_consent: 'consent') }
      let!(:adult)  { FactoryGirl.create(:person) }

      it 'returns adults' do
        expect(Person.adults_or_have_consent).to include(adult)
      end

      it 'returns children with parental consent' do
        expect(Person.adults_or_have_consent).to include(child3)
        expect(Person.adults_or_have_consent).to_not include(child1, child2)
      end
    end
  end

  describe '#create_as_stream_item' do
    let!(:person) { FactoryGirl.create(:person) }

    it 'creates a new stream item' do
      expect(StreamItem.last.attributes).to include(
        'title'     => person.name,
        'person_id' => person.id
      )
    end
  end

  describe '#update_stream_item' do
    let!(:person) { FactoryGirl.create(:person) }
    let(:stream_item_spy) { spy('stream_item') }

    before do
      allow(person).to receive(:stream_item).and_return(stream_item_spy)
    end

    context 'given no relevant changes' do
      before do
        person.reload
        person.email = 'new@example.com'
        person.save!
      end

      it 'does not update the stream item' do
        expect(stream_item_spy).not_to have_received(:save!)
      end
    end

    context 'given the email went away' do
      before do
        person.reload
        person.email = ''
        person.save!
      end

      it 'updates the stream item' do
        expect(stream_item_spy).to have_received(:save!)
      end
    end

    context 'given the name changed' do
      before do
        person.reload
        person.suffix = 'Jr.'
        person.save!
      end

      it 'updates the stream item' do
        expect(stream_item_spy).to have_received(:save!)
      end
    end
  end

  describe '#position' do
    context 'given a family with three people in it' do
      let!(:family) { FactoryGirl.create(:family) }
      let!(:head)   { FactoryGirl.create(:person, family: family, child: false, first_name: 'Tim',    last_name: 'Morgan') }
      let!(:spouse) { FactoryGirl.create(:person, family: family, child: false, first_name: 'Jennie', last_name: 'Morgan') }
      let!(:child)  { FactoryGirl.create(:person, family: family, child: true,  first_name: 'Mac',    last_name: 'Morgan') }

      it 'can be reordered' do
        head.insert_at(3)

        expect(spouse.reload.position).to eq(1)
        expect(child.reload.position).to eq(2)
        expect(head.reload.position).to eq(3)
      end
    end
  end

  describe '#primary_emailer=' do
    context 'setting to true on one family member when other already has it set' do
      let(:husband) { FactoryGirl.create(:person, first_name: 'John', email: 'shared@example.com', primary_emailer: true) }
      let(:spouse)  { FactoryGirl.create(:person, first_name: 'Jane', email: 'shared@example.com', family: husband.family) }

      it 'sets the value to false on others with the same email' do
        spouse.primary_emailer = true
        spouse.save
        expect(spouse.reload).to be_primary_emailer
        expect(husband.reload).to_not be_primary_emailer
      end
    end
  end

  describe '#destroy' do
    let(:person) { FactoryGirl.create(:person) }

    it 'destroys the associated stream_item' do
      expect(person.stream_item).to be
      person.destroy
      expect { person.stream_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#suffix=' do
    let(:person) { FactoryGirl.build(:person) }

    it 'sets to nil if blank' do
      person.suffix = ''
      person.valid? # trigger callback
      expect(person.suffix).to be_nil
    end
  end

  describe '#gender=' do
    let(:person) { FactoryGirl.build(:person) }

    it 'sets to nil if blank' do
      person.gender = ''
      person.valid? # trigger callback
      expect(person.gender).to be_nil
    end

    it 'sets with capital letter' do
      person.gender = 'male'
      person.valid? # trigger callback
      expect(person.gender).to eq('Male')
    end
  end

  describe '#update_feed_code' do
    let(:existing) { FactoryGirl.create(:person) }
    let(:person)   { FactoryGirl.build(:person) }

    context 'given a collision in code generation' do
      before do
        existing.update_attribute(:feed_code, 'abc123')
        person.family.save # saving the family calls SecureRandom.hex in the GeocoderJob, so get that out of the way
        allow(SecureRandom).to receive(:hex).and_return('abc123', 'xyz987')
      end

      it 'generates a new code until it is unique' do
        person.save!
        expect(SecureRandom).to have_received(:hex).with(50).twice
        expect(person.feed_code).to eq('xyz987')
      end
    end
  end

  describe '#relationships=' do
    context 'given a string' do
      let(:person) { FactoryGirl.build(:person) }
      let(:child)  { FactoryGirl.create(:person, legacy_id: 1001) }
      let(:father) { FactoryGirl.create(:person, legacy_id: 1002) }
      let(:neighbor) { FactoryGirl.create(:person, legacy_id: 1003) }

      before do
        person.relationships = "#{father.legacy_id}[father],#{child.legacy_id}[Son],#{neighbor.legacy_id}[Neighbor]"
      end

      it 'sets the attributes' do
        expect(person.relationships.map(&:attributes)).to match_array([
          include('name' => 'father', 'other_name' => nil,        'related_id' => father.id),
          include('name' => 'son',    'other_name' => nil,        'related_id' => child.id),
          include('name' => 'other',  'other_name' => 'Neighbor', 'related_id' => neighbor.id)
        ])
      end
    end
  end

  describe '#update_relationships_hash' do
    let(:person) { FactoryGirl.build(:person) }

    context 'given no relationships' do
      it 'generates a sha1 hash of an empty string' do
        person.update_relationships_hash
        expect(person.relationships_hash).to eq(Digest::SHA1.hexdigest(''))
      end
    end

    context 'given a relationship' do
      let(:mother) { FactoryGirl.create(:person, legacy_id: 111) }

      before do
        person.save!
        person.relationships.create!(related: mother, name: 'mother')
      end

      it 'generates a sha1 hash of of the legacy_id and relationship name' do
        person.update_relationships_hash
        expect(person.relationships_hash).to eq(Digest::SHA1.hexdigest('111[Mother]'))
      end
    end
  end

  describe '#business_categories' do
    before do
      FactoryGirl.create_list(:person, 2, business_category: 'foo')
    end

    it 'returns an array of unique category names' do
      expect(Person.business_categories).to eq(['foo'])
    end
  end

  describe '#custom_types' do
    before do
      FactoryGirl.create_list(:person, 2, custom_type: 'foo')
    end

    it 'returns an array of unique type names' do
      expect(Person.custom_types).to eq(['foo'])
    end
  end

  describe 'admin records deleted after person is destroyed' do
    context 'admin user is destroyed' do
      let!(:person) { FactoryGirl.create(:person, :admin_edit_profiles) }
      let!(:admin)  { person.admin }

      before do
        person.destroy
      end

      it 'deletes the admin record' do
        expect { admin.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'admin user is destroyed for real' do
      let!(:person) { FactoryGirl.create(:person, :admin_edit_profiles) }
      let!(:admin)  { person.admin }

      before do
        person.destroy_for_real
      end

      it 'deletes the admin record' do
        expect { admin.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update_last_seen_at' do
    context 'if it was already updated recently' do
      let(:person) do
        FactoryGirl.create(
          :person,
          last_seen_at: 10.minutes.ago
        )
      end

      before do
        allow(person).to receive(:update_column)
        person.update_last_seen_at
      end

      it 'does nothing' do
        expect(person).not_to have_received(:update_column)
      end
    end

    context 'it is currently nil' do
      let(:person) do
        FactoryGirl.create(
          :person,
          last_seen_at: nil
        )
      end

      before do
        person.update_last_seen_at
      end

      it 'updates to the current time' do
        expect(person.reload.last_seen_at).to be_within(1).of(Time.current)
      end
    end

    context 'it was updated a long time ago' do
      let(:person) do
        FactoryGirl.create(
          :person,
          last_seen_at: 2.hours.ago
        )
      end

      before do
        person.update_last_seen_at
      end

      it 'updates to the current time' do
        expect(person.reload.last_seen_at).to be_within(1).of(Time.current)
      end
    end
  end
end
