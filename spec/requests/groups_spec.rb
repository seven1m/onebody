require_relative '../rails_helper'

describe GroupsController, type: :request do
  before do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, name: 'Small Group', category: 'Small Groups')
    @other_group = FactoryGirl.create(:group, name: 'Other Group', category: 'Volunteer Groups')
  end

  context 'user is a group admin' do
    before do
      @user.update_attribute(:admin, Admin.create!(manage_groups: true))
      sign_in_as @user
      @group.approved = false
      @group.save!
    end

    it 'should show groups pending approval' do
      get '/groups'
      assert_select 'body', html: /pending approval.*Small\sGroup/m
      get '/groups?category=Small+Groups'
      assert_select 'body', html: /Small Group/
    end

    it 'should show hidden groups matching by category' do
      get '/groups?category=Small+Groups'
      expect(response).to be_success
      assert_select 'body', html: /Small Group/
    end

    it 'should show allow user to Approve group' do
      get "/groups/#{@group.id}"
      assert_select 'body', html: /Approve Group/
      put "/groups/#{@group.id}?group[approved]=true"
      expect(response).to redirect_to(@group)
      assert_select 'body', html: /Approve Group/, count: 0
    end
  end

  it 'should not show pending groups' do
    @group.approved = false
    @group.save!
    get '/groups'
    assert_select 'body', html: /Small Group/, count: 0
  end

  context 'enable/disable email' do
    before do
      Membership.create!(person: @user, group: @group)
    end

    context 'with code' do
      it 'should disable email' do
        patch "/groups/#{@group.id}/memberships/#{@user.id}",
              params: { code: @user.feed_code, email: 'off' }
        expect(@group.get_options_for(@user).get_email).not_to be
      end

      it 'should enable email' do
        @group.set_options_for(@user, get_email: false)
        patch "/groups/#{@group.id}/memberships/#{@user.id}",
              params: { code: @user.feed_code, email: 'on' }
        expect(@group.get_options_for(@user).get_email).to be
      end
    end

    context 'while signed in' do
      before do
        sign_in_as @user
      end

      it 'should disable email' do
        put "/groups/#{@group.id}/memberships/#{@user.id}?email=off",
            headers: { referer: "/groups/#{@group.id}" }
        expect(@group.get_options_for(@user).get_email).not_to be
      end

      it 'should enable email' do
        put "/groups/#{@group.id}/memberships/#{@user.id}?email=on",
            headers: { referer: "/groups/#{@group.id}" }
        expect(@group.get_options_for(@user).get_email).to be
      end
    end
  end
end
