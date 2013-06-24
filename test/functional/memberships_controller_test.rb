require_relative '../test_helper'

class MembershipsControllerTest < ActionController::TestCase

  setup do
    @admin = FactoryGirl.create(:person, :admin => Admin.create!(:edit_profiles => true, :manage_groups => true))
    @person = FactoryGirl.create(:person)
    @group1 = FactoryGirl.create(:group)
    @group2 = FactoryGirl.create(:group)
    @person.memberships.create!(:group => @group1)
  end

  should "add/remote group memberships" do
    post :batch, {:ids => [@group2.id], :person_id => @person.id, :format => :js}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal [@group2], @person.reload.groups.all
  end

end
