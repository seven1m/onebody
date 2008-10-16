require File.dirname(__FILE__) + '/../test_helper'

class GroupiesControllerTest < ActionController::TestCase
  
  def setup
    @group = Group.forge(:category => 'Small Groups')
    15.times { @group.memberships.create!(:person => Person.forge) }
    @person = @group.people.last
  end
  
  should "show all groupies" do
    get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
    assert_equal 14, assigns(:people).length
  end
  
end
