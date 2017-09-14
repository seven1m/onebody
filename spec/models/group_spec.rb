require 'rails_helper'

describe Group, type: :model do
  before do
    @person = Person.logged_in = FactoryGirl.create(:person)
    # all are approved...
    @group = FactoryGirl.create(:group, creator_id: @person.id, category: 'Small Groups')
    FactoryGirl.create(:group, category: 'foo', hidden: false)
    FactoryGirl.create(:group, category: 'foo', hidden: false)
    FactoryGirl.create(:group, category: 'bar', hidden: true)
  end

  describe '#update_memberships' do
    context 'given user has a single class code' do
      before do
        @person = FactoryGirl.create(:person, classes: 'foo')
        @group.membership_mode = 'link_code'
        @group.link_code = 'foo'
        @group.save
      end

      it 'adds the person to the group' do
        expect(@group.people.reload).to match([@person])
      end
    end

    context 'given user has multiple class codes' do
      before do
        @person = FactoryGirl.create(:person, classes: 'foo,bar,baz')
        @group.membership_mode = 'link_code'
        @group.link_code = 'bar'
        @group.save
      end

      it 'adds the person to the group' do
        expect(@group.people.reload).to match([@person])
      end
    end

    context 'given user has multiple class codes with roles' do
      before do
        @person = FactoryGirl.create(:person, classes: 'foo[member],bar[participant|group leader],baz')
        @group.membership_mode = 'link_code'
        @group.link_code = 'bar'
        @group.save
      end

      it 'adds the person to the group' do
        expect(@group.people.reload).to match([@person])
      end

      it 'adds the roles to the membership' do
        expect(@group.memberships.first.roles).to match(['participant', 'group leader'])
      end

      context 'user roles change' do
        before do
          @person.update_attribute(:classes, 'foo,bar[parent],baz')
          @group.save
        end

        it 'changes the roles on the membership' do
          expect(@group.memberships.first.roles).to match(['parent'])
        end
      end

      context 'user code is removed' do
        before do
          @person.update_attribute(:classes, 'foo,baz')
          @group.save
        end

        it 'removes the membership' do
          expect(@group.memberships.count).to eq(0)
        end
      end
    end

    context 'group is set to auto_add "adults"' do
      before do
        @person2 = FactoryGirl.create(:person)
        @child = FactoryGirl.create(:person, child: true)
        @group.update_attribute(:membership_mode, 'adults')
      end

      it 'adds all people' do
        expect(@group.people.reload).to include(@person, @person2)
      end
    end
  end

  context 'given one group set as parents_of for another' do
    before do
      @head = FactoryGirl.create(:person)
      @spouse = FactoryGirl.create(:person, family: @head.family)
      @child = FactoryGirl.create(:person, family: @head.family, child: true)
      @group.memberships.create!(person: @child)
      @group2 = FactoryGirl.create(:group, membership_mode: 'parents_of', parents_of: @group.id)
    end

    it 'should update its membership based on a parents_of selection' do
      expect(@group2.people.count).to eq(2)
      expect(@group2.reload.people).to include(@head)
      expect(@group2.people).to include(@spouse)
    end
  end

  it 'should list all group categories' do
    cats = Group.categories
    expect(cats.keys.length).to eq(2)
    # only two that are not hidden, not private, and are approved
    expect(cats['Small Groups']).to eq(1)
    expect(cats['foo']).to eq(2)
    expect(cats['bar']).to be_nil
    expect(cats['Subscription']).to be_nil
  end

  it 'should list all group categories including hidden and pending approval if user can manage groups' do
    @person.admin = Admin.create(manage_groups: true); @person.save
    cats = Group.categories
    expect(cats.keys.length).to eq(3)
    expect(cats['Small Groups']).to eq(1)
    expect(cats['foo']).to eq(2)
    expect(cats['bar']).to eq(1)
    expect(cats['Subscription']).to be_nil
  end

  it 'should get attendance records by date per person' do
    @group.memberships.create!(person_id: @person.id)
    @group.memberships.create!(person_id: FactoryGirl.create(:person).id)
    records = @group.get_people_attendance_records_for_date('2008-07-22')
    expect(records.length).to eq(2)
    expect(records.any?(&:last)).not_to be
    @group.attendance_records.create!(person_id: @person.id, attended_at: '2008-07-22')
    records = @group.get_people_attendance_records_for_date('2008-07-22')
    expect(records.length).to eq(2)
    expect(records.select(&:last).length).to eq(1)
  end

  it 'should be able to parse out the Google Calendar account info from an XML link' do
    @group.update_attributes!(gcal_private_link: 'http://www.google.com/calendar/feeds/4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com/private-2a2453bc8ef65dddf11a4f43a133df12/basic')
    expect(@group.gcal_account).to eq('4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com')
  end

  it 'should be able to parse out the Google Calendar account info from an HTML link' do
    @group.update_attributes!(gcal_private_link: 'http://www.google.com/calendar/hosted/timmorgan.org/embed?src=4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com&ctz=America/Chicago&pvttk=2a2453bc8ef65dddf11a4f43a133df12')
    expect(@group.gcal_account).to eq('4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com')
  end

  describe 'share_token' do
    it 'gets set on creation' do
      expect(@group.share_token).to match(/^[0-9a-f]{50}$/)
    end
  end

  describe 'geocoding' do
    context 'group with address' do
      let(:location) { "650 S. Peoria Ave.\nTulsa OK 74120" }
      let(:group)    { FactoryGirl.create(:group, location: location) }

      before do
        Geocoder::Lookup::Test.add_stub(
          "650 S. Peoria Ave.\nTulsa OK 74120, US", [
            {
              'latitude'     => 36.151305,
              'longitude'    => -95.975393,
              'address'      => 'Tulsa, OK, USA',
              'state'        => 'Oklahoma',
              'state_code'   => 'OK',
              'country'      => 'United States',
              'country_code' => 'US'
            }
          ]
        )
      end

      it 'sets latitude and longitude' do
        expect(group.reload.attributes).to include(
          'latitude'  => within(0.00001).of(36.151305),
          'longitude' => within(0.00001).of(-95.975393)
        )
      end

      context 'address is removed' do
        before do
          Geocoder::Lookup::Test.add_stub(
            ', US', [
              {
                'precision' => 'APPROXIMATE',
                'latitude'  => 35,
                'longitude' => -95
              }
            ]
          )
        end

        before do
          group.location = ''
          group.save!
        end

        it 'removes latitude and longitude' do
          expect(group.latitude).to be_nil
          expect(group.longitude).to be_nil
        end
      end
    end
  end

  describe 'validations' do
    context 'group does not belong to a Checkin GroupTime and does not have attendance enabled' do
      before do
        @group.update_attribute(:attendance, false)
      end

      it 'is valid' do
        expect(@group).to be_valid
      end
    end

    context 'group belongs to a Checkin GroupTime and does not have attendance enabled' do
      before do
        @group.update_attribute(:attendance, false)
        @checkin_time = FactoryGirl.create(:checkin_time)
        @checkin_time.group_times.create!(group: @group)
      end

      it 'is invalid' do
        expect(@group).not_to be_valid
      end
    end

    context 'group belongs to a Checkin GroupTime and has attendance enabled' do
      before do
        @group.update_attribute(:attendance, true)
        @checkin_time = FactoryGirl.create(:checkin_time)
        @checkin_time.group_times.create!(group: @group)
      end

      it 'is valid' do
        expect(@group).to be_valid
      end
    end
  end
end
