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
  
end
