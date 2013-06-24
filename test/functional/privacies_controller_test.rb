require_relative '../test_helper'

class PrivaciesControllerTest < ActionController::TestCase

  should "redirect to edit action" do
    get :show, {group_id: groups(:college).id, membership_id: memberships(:peter_in_college_group).id},
      {logged_in_id: people(:peter).id}
    assert_redirected_to edit_group_membership_privacy_path(groups(:college), memberships(:peter_in_college_group))
    get :show, {person_id: people(:peter).id}, {logged_in_id: people(:peter).id}
    assert_redirected_to edit_person_privacy_path(people(:peter), anchor: 'p3')
  end

  should "edit membership privacy" do
    people(:peter).update_attributes!(
      share_address:      false,
      share_mobile_phone: false,
      share_home_phone:   false,
      share_work_phone:   false,
      share_fax:          false,
      share_email:        false,
      share_birthday:     false,
      share_anniversary:  false
    )
    get :edit, {person_id: people(:peter).id}, {logged_in_id: people(:peter).id}
    assert_response :success
    assert_template :edit
    post :update, {
      person_id: people(:peter).id,
      memberships: {
        memberships(:peter_in_college_group).id => {
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
    }, {logged_in_id: people(:peter).id}
    assert_redirected_to person_path(people(:peter).id)
    assert  memberships(:peter_in_college_group).reload.share_address?
    assert  memberships(:peter_in_college_group).share_mobile_phone?
    assert  memberships(:peter_in_college_group).share_home_phone?
    assert !memberships(:peter_in_college_group).share_work_phone?
    assert !memberships(:peter_in_college_group).share_fax?
    assert  memberships(:peter_in_college_group).share_email?
    assert !memberships(:peter_in_college_group).share_birthday?
    assert !memberships(:peter_in_college_group).share_anniversary?
  end

  should "only allow admins and adult family members to edit privacy" do
    get :edit, {person_id: people(:peter).id}, {logged_in_id: people(:jeremy).id}
    assert_response :unauthorized
    post :update, {person_id: people(:peter).id, person: {}}, {logged_in_id: people(:jeremy).id}
    assert_response :unauthorized
    get :edit, {person_id: people(:peter).id}, {logged_in_id: people(:tim).id}
    assert_response :success
  end

  should "edit family privacy" do
    get :edit, {person_id: people(:peter).id}, {logged_in_id: people(:peter).id}
    assert_response :success
    assert_template 'edit'
    post :update, {
      person_id: people(:peter).id,
      family: {
        people_attributes: {
          '0' => {
            id:                 people(:peter).id,
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
    }, {logged_in_id: people(:peter).id}
    assert_redirected_to person_path(people(:peter).id)
    assert  people(:peter).reload.share_address?
    assert  people(:peter).share_mobile_phone?
    assert  people(:peter).share_home_phone?
    assert !people(:peter).share_work_phone?
    assert !people(:peter).share_fax?
    assert  people(:peter).share_email?
    assert !people(:peter).share_birthday?
    assert !people(:peter).share_anniversary?
    assert !people(:peter).share_activity?
  end

end
