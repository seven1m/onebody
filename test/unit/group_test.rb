require "#{File.dirname(__FILE__)}/../test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @person = Person.logged_in = Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    2.times { Group.forge(:category => 'foo') }
    Group.forge(:category => 'bar', :hidden => true)
  end

  should "list all group categories" do
    cats = Group.categories
    assert_equal 2, cats.keys.length
    assert_equal 2, cats['Small Groups']
    assert_equal 2, cats['foo']
    assert cats['bar'].nil?
    assert cats['Subscription'].nil?
  end
  
  should "list all group categories including hidden and pending approval if user can manage groups" do
    @person.admin = Admin.create(:manage_groups => true); @person.save
    cats = Group.categories
    assert_equal 3, cats.keys.length
    assert_equal 3, cats['Small Groups']
    assert_equal 2, cats['foo']
    assert_equal 1, cats['bar']
    assert cats['Subscription'].nil?
  end
  
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
  
  should "know its admins" do
    assert_equal 0, @group.admins.count
    @admin = Person.forge
    @group.memberships.create!(:person_id => @admin.id, :admin => true)
    assert_equal 1, @group.admins.count
  end
  
  should "guess its leader" do
    assert_nil @group.leader
    @admin = Person.forge
    @group.memberships.create!(:person_id => @admin.id, :admin => true)
    assert_equal @admin, @group.leader
    @group.update_attributes! :leader_id => @person.id
    assert_equal @person, @group.leader
  end
end
