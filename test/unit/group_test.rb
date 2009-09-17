require "#{File.dirname(__FILE__)}/../test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @person = Person.logged_in = Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    2.times { Group.forge(:category => 'foo', :hidden => false) }
    Group.forge(:category => 'bar', :hidden => true)
  end
  
  # should "update its membership based on a link_code" do
  #   3.times { Person.forge(:classes => 'foo') }
  #   2.times { Person.forge(:classes => 'fooz,bar,baz') }
  #   assert_equal 0, @group.people.count
  #   @group.link_code = 'foo'
  #   @group.save
  #   assert_equal 3, @group.people.count
  #   # should delete 3 old people and add 2 new people
  #   @group.link_code = 'bar'
  #   @group.save
  #   assert_equal 2, @group.reload.people.count
  #   # should delete all people
  #   @group.link_code = nil
  #   @group.save
  #   assert_equal 0, @group.reload.people.count
  # end
  # 
  # should "update its membership based on a parents_of selection" do
  #   @group.memberships.create!(:person => people(:mac))
  #   @group2 = Group.forge(:parents_of => @group.id)
  #   assert_equal 2, @group2.people.count
  #   assert @group2.reload.people.include?(people(:tim))
  #   assert @group2.people.include?(people(:jennie))
  # end
  # 
  # should "list all group categories" do
  #   cats = Group.categories
  #   assert_equal 2, cats.keys.length
  #   assert_equal 2, cats['Small Groups']
  #   assert_equal 2, cats['foo']
  #   assert cats['bar'].nil?
  #   assert cats['Subscription'].nil?
  # end
  # 
  # should "list all group categories including hidden and pending approval if user can manage groups" do
  #   @person.admin = Admin.create(:manage_groups => true); @person.save
  #   cats = Group.categories
  #   assert_equal 3, cats.keys.length
  #   assert_equal 3, cats['Small Groups']
  #   assert_equal 2, cats['foo']
  #   assert_equal 1, cats['bar']
  #   assert cats['Subscription'].nil?
  # end
  # 
  should "get attendance records by date per person" do
    @group.memberships.create!(:person_id => @person.id)
    @group.memberships.create!(:person_id => Person.forge.id)
    records = @group.get_people_attendance_records_for_date('2008-07-22')
    assert_equal 2, records.length
    assert !records.any? { |r| r.last }
    @group.attendance_records.create!(:person_id => @person.id, :attended_at => '2008-07-22')
    records = @group.get_people_attendance_records_for_date(Date.parse('2008-07-22'))
    assert_equal 2, records.length
    assert_equal 1, records.select { |r| r.last }.length
  end
  
  should "be able to parse out the Google Calendar account info from an XML link" do
    @group.update_attributes!(:gcal_private_link => 'http://www.google.com/calendar/feeds/4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com/private-2a2453bc8ef65dddf11a4f43a133df12/basic')
    assert_equal '4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com', @group.gcal_account
  end
  
  should "be able to parse out the Google Calendar account info from an HTML link" do
    @group.update_attributes!(:gcal_private_link => 'http://www.google.com/calendar/hosted/timmorgan.org/embed?src=4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com&ctz=America/Chicago&pvttk=2a2453bc8ef65dddf11a4f43a133df12')
    assert_equal '4azsf34hrgq1t3lkjh4sdewzxc%40group.calendar.google.com', @group.gcal_account
  end
end
