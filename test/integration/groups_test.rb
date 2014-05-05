require "#{File.dirname(__FILE__)}/../test_helper"

class GroupsTest < ActionController::IntegrationTest

  setup do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, name: 'Small Group', category: 'Small Groups')
    @other_group = FactoryGirl.create(:group, name: 'Other Group', category: 'Volunteer Groups')
  end

  context 'user is a group admin' do
    setup do
      @user.update_attribute(:admin, Admin.create!(manage_groups: true))
      sign_in_as @user
      @group.approved = false
      @group.save!
    end

    should 'show groups pending approval' do
      get '/groups'
      assert_select 'body', html: /pending approval.*Small\sGroup/m
      get '/groups?category=Small+Groups'
      assert_select 'body', html: /Small Group/
    end

    should 'show hidden groups matching by category' do
      get '/groups?category=Small+Groups'
      assert_response :success
      assert_select 'body', html: /Small Group/
    end

    should 'show allow user to Approve group' do
      get "groups/#{@group.id}"
      assert_select 'body', html: /Approve Group/
      put "/groups/#{@group.id}?group[approved]=true"
      assert_redirected_to @group
      assert_select 'body', html: /Approve Group/, count: 0
    end
  end

  should 'not show pending groups' do
    @group.approved = false
    @group.save!
    get '/groups'
    assert_select 'body', html: /Small Group/, count: 0
  end

  context 'enable/disable email' do
    setup do
      Membership.create!(person: @user, group: @group)
    end

    context 'with code' do
      should 'disable email' do
        get "/groups/#{@group.id}/memberships/#{@user.id}?code=#{@user.feed_code}&email=off"
        assert !@group.get_options_for(@user).get_email
      end

      should 'enable email' do
        get "/groups/#{@group.id}/memberships/#{@user.id}?code=#{@user.feed_code}&email=on"
        assert @group.get_options_for(@user).get_email
      end
    end

    context 'while signed in' do
      setup do
        sign_in_as @user
      end

      should 'disable email' do
        put "/groups/#{@group.id}/memberships/#{@user.id}?email=off"
        assert !@group.get_options_for(@user).get_email
      end

      should 'enable email' do
        put "/groups/#{@group.id}/memberships/#{@user.id}?email=on"
        assert @group.get_options_for(@user).get_email
      end
    end
  end
end
