require_relative '../test_helper'

class PrivaciesControllerTest < ActionController::TestCase

  setup do
    @group = FactoryGirl.create(:group)
    @user = FactoryGirl.create(:person) # peter
    @membership = @group.memberships.create(person: @user)
  end

  should "redirect to edit action" do
    get :show, {group_id: @group.id, membership_id: @membership.id},
      {logged_in_id: @user.id}
    assert_redirected_to edit_group_membership_privacy_path(@group, @membership)
    get :show, {person_id: @user.id}, {logged_in_id: @user.id}
    assert_redirected_to edit_person_privacy_path(@user, anchor: "p#{@user.id}")
  end

  should "edit membership privacy" do
    @user.update_attributes!(
      share_address:      false,
      share_mobile_phone: false,
      share_home_phone:   false,
      share_work_phone:   false,
      share_fax:          false,
      share_email:        false,
      share_birthday:     false,
      share_anniversary:  false
    )
    get :edit, {person_id: @user.id}, {logged_in_id: @user.id}
    assert_response :success
    assert_template :edit
    post :update, {
      person_id: @user.id,
      family: {
        people_attributes: {}
      },
      memberships: {
        @membership.id => {
          share_address:      true,
          share_mobile_phone: true,
          share_home_phone:   true,
          share_work_phone:   false,
          share_fax:          false,
          share_email:        true,
          share_birthday:     false,
          share_anniversary:  false
        }
      }
    }, {logged_in_id: @user.id}
    assert_redirected_to person_path(@user.id)
    assert  @membership.reload.share_address?
    assert  @membership.share_mobile_phone?
    assert  @membership.share_home_phone?
    assert !@membership.share_work_phone?
    assert !@membership.share_fax?
    assert  @membership.share_email?
    assert !@membership.share_birthday?
    assert !@membership.share_anniversary?
  end

  should "only allow admins and adult family members to edit privacy" do
    @stranger = FactoryGirl.create(:person)
    @admin = FactoryGirl.create(:person, :super_admin)
    get :edit, {person_id: @user.id}, {logged_in_id: @stranger.id}
    assert_response :unauthorized
    post :update, {person_id: @user.id, person: {}}, {logged_in_id: @stranger.id}
    assert_response :unauthorized
    get :edit, {person_id: @user.id}, {logged_in_id: @admin.id}
    assert_response :success
  end

  should "edit family privacy" do
    get :edit, {person_id: @user.id}, {logged_in_id: @user.id}
    assert_response :success
    assert_template 'edit'
    post :update, {
      person_id: @user.id,
      family: {
        people_attributes: {
          '0' => {
            id:                 @user.id,
            share_address:      true,
            share_mobile_phone: true,
            share_home_phone:   true,
            share_work_phone:   false,
            share_fax:          false,
            share_email:        true,
            share_birthday:     false,
            share_anniversary:  false,
            share_activity:     false
          }
        }
      }
    }, {logged_in_id: @user.id}
    assert_redirected_to person_path(@user.id)
    assert  @user.reload.share_address?
    assert  @user.share_mobile_phone?
    assert  @user.share_home_phone?
    assert !@user.share_work_phone?
    assert !@user.share_fax?
    assert  @user.share_email?
    assert !@user.share_birthday?
    assert !@user.share_anniversary?
    assert !@user.share_activity?
  end

end
