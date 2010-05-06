require File.dirname(__FILE__) + '/../test_helper'

class AttendanceControllerTest < ActionController::TestCase

  def setup
    @person = Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    @group.memberships.create(:person => @person, :admin => true)
  end

  should "store and retrieve attendance records based on date" do
    post :batch, {:attended_at => '2009-12-01', :group_id => @group.id, :ids => [@person.id]}, {:logged_in_id => @person.id}
    get  :index, {:attended_at => '2009-12-01', :group_id => @group.id}, {:logged_in_id => @person.id}
    assert_equal 1, assigns(:records).length
    person, attended = assigns(:records).first
    assert attended
  end

  should "overwrite existing records" do
    post :batch, {:attended_at => '2009-12-01', :group_id => @group.id, :ids => [@person.id]}, {:logged_in_id => @person.id}
    post :batch, {:attended_at => '2009-12-01', :group_id => @group.id, :ids => []}, {:logged_in_id => @person.id}
    get  :index, {:attended_at => '2009-12-01', :group_id => @group.id}, {:logged_in_id => @person.id}
    assert_equal 1, assigns(:records).length
    person, attended = assigns(:records).first
    assert !attended
  end

  should "record attendance for people in the database" do
    post :create, {:attended_at => '2009-12-01 9:00', :group_id => @group.id, :ids => [@person.id]}, {:logged_in_id => @person.id}
    assert_response :redirect
    @records = AttendanceRecord.all
    assert_equal 1, @records.length
    assert_equal @person.first_name, @records.first.first_name
  end

  should "record attendance for people not in the database" do
    post :create, {:attended_at => '2009-12-01 9:00', :group_id => @group.id, :person => {'first_name' => 'Jimmy', 'last_name' => 'Smith', 'age' => '2 yr'}}, {:logged_in_id => @person.id}
    assert_response :redirect
    @records = AttendanceRecord.all
    assert_equal 1, @records.length
    assert_equal 'Jimmy', @records.first.first_name
  end

  should "respond to a json request with status='success'" do
    post :create, {:attended_at => '2009-12-01 9:00', :group_id => @group.id, :ids => [@person.id], :person => {'first_name' => 'Jimmy', 'last_name' => 'Smith', 'age' => '2 yr'}, :format => 'json'}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 'success', JSON.parse(@response.body)['status']
  end

end
