require File.dirname(__FILE__) + '/../test_helper'

class MembershipsControllerTest < ActionController::TestCase

  setup do
    @admin = Person.forge(:admin => Admin.create!(:edit_profiles => true, :manage_groups => true))
    @person = Person.forge
    @group1, @group2 = Group.forge, Group.forge
    @person.memberships.create!(:group => @group1)
  end

  should "add/remote group memberships" do
    post :batch, {:ids => [@group2.id], :person_id => @person.id, :format => :js}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal [@group2], @person.reload.groups.all
  end

end
