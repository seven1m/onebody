require_relative '../spec_helper'

describe Group do
  before do
    @person = Person.logged_in = FactoryGirl.create(:person)
    # all are approved...
    @group = FactoryGirl.create(:group, creator_id: @person.id, category: 'Small Groups')
    FactoryGirl.create(:group, category: 'foo', hidden: false)
    FactoryGirl.create(:group, category: 'foo', hidden: false)
    FactoryGirl.create(:group, category: 'bar', hidden: true)
  end

  it "should update its membership based on a link_code" do
    3.times { FactoryGirl.create(:person, classes: 'foo') }
    2.times { FactoryGirl.create(:person, classes: 'fooz,bar,baz') }
    expect(@group.people.count).to eq(0)
    @group.link_code = 'foo'
    @group.save
    expect(@group.people.count).to eq(3)
    # should delete 3 old people and add 2 new people
    @group.link_code = 'bar'
    @group.save
    expect(@group.reload.people.count).to eq(2)
    # should delete all people
    @group.link_code = nil
    @group.save
    expect(@group.reload.people.count).to eq(0)
  end

  context 'given one group set as parents_of for another' do
    before do
      @head = FactoryGirl.create(:person)
      @spouse = FactoryGirl.create(:person, family: @head.family)
      @child = FactoryGirl.create(:person, family: @head.family, child: true)
      @group.memberships.create!(person: @child)
      @group2 = FactoryGirl.create(:group, parents_of: @group.id)
    end

    it 'should update its membership based on a parents_of selection' do
      expect(@group2.people.count).to eq(2)
      expect(@group2.reload.people).to include(@head)
      expect(@group2.people).to include(@spouse)
    end
  end

  it "should list all group categories" do
    cats = Group.categories
    expect(cats.keys.length).to eq(2)
    # only two that are not hidden, not private, and are approved
    expect(cats["Small Groups"]).to eq(1)
    expect(cats["foo"]).to eq(2)
    expect(cats['bar']).to be_nil
    expect(cats['Subscription']).to be_nil
  end

  it "should list all group categories including hidden and pending approval if user can manage groups" do
    @person.admin = Admin.create(manage_groups: true); @person.save
    cats = Group.categories
    expect(cats.keys.length).to eq(3)
    expect(cats["Small Groups"]).to eq(1)
    expect(cats["foo"]).to eq(2)
    expect(cats["bar"]).to eq(1)
    expect(cats['Subscription']).to be_nil
  end

  it "should get attendance records by date per person" do
    @group.memberships.create!(person_id: @person.id)
    @group.memberships.create!(person_id: FactoryGirl.create(:person).id)
    records = @group.get_people_attendance_records_for_date('2008-07-22')
    expect(records.length).to eq(2)
    expect(records.any? { |r| r.last }).not_to be
    @group.attendance_records.create!(person_id: @person.id, attended_at: '2008-07-22')
    records = @group.get_people_attendance_records_for_date('2008-07-22')
    expect(records.length).to eq(2)
    expect(records.select do |r|
  r.last
end.length).to eq(1)
  end

  it "should be able to parse out the Google Calendar account info from an XML link" do
    @group.update_attributes!(gcal_private_link: 'http://www.google.com/calendar/feeds/4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com/private-2a2453bc8ef65dddf11a4f43a133df12/basic')
    expect(@group.gcal_account).to eq("4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com")
  end

  it "should be able to parse out the Google Calendar account info from an HTML link" do
    @group.update_attributes!(gcal_private_link: 'http://www.google.com/calendar/hosted/timmorgan.org/embed?src=4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com&ctz=America/Chicago&pvttk=2a2453bc8ef65dddf11a4f43a133df12')
    expect(@group.gcal_account).to eq("4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com")
  end
end
