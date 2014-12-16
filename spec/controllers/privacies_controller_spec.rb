require_relative '../rails_helper'

describe PrivaciesController, type: :controller do

  before do
    @group = FactoryGirl.create(:group)
    @user = FactoryGirl.create(:person) # peter
    @membership = @group.memberships.create(person: @user)
  end

  it "should redirect to edit action" do
    get :show, {group_id: @group.id, membership_id: @membership.id},
      {logged_in_id: @user.id}
    expect(response).to redirect_to(edit_group_membership_privacy_path(@group, @membership))
    get :show, {person_id: @user.id}, {logged_in_id: @user.id}
    expect(response).to redirect_to(edit_person_privacy_path(@user, anchor: "p#{@user.id}"))
  end

  it "should edit membership privacy" do
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
    expect(response).to be_success
    expect(response).to render_template(:edit)
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
    expect(response).to redirect_to(person_path(@user.id))
    expect( @membership.reload).to be_share_address
    expect( @membership).to be_share_mobile_phone
    expect( @membership).to be_share_home_phone
    expect(@membership).to_not be_share_work_phone
    expect(@membership).to_not be_share_fax
    expect( @membership).to be_share_email
    expect(@membership).to_not be_share_birthday
    expect(@membership).to_not be_share_anniversary
  end

  it "should only allow admins and adult family members to edit privacy" do
    @stranger = FactoryGirl.create(:person)
    @admin = FactoryGirl.create(:person, :super_admin)
    get :edit, {person_id: @user.id}, {logged_in_id: @stranger.id}
    expect(response).to be_unauthorized
    post :update, {person_id: @user.id, person: {}}, {logged_in_id: @stranger.id}
    expect(response).to be_unauthorized
    get :edit, {person_id: @user.id}, {logged_in_id: @admin.id}
    expect(response).to be_success
  end

  it "should edit family privacy" do
    get :edit, {person_id: @user.id}, {logged_in_id: @user.id}
    expect(response).to be_success
    expect(response).to render_template('edit')
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
    expect(response).to redirect_to(person_path(@user.id))
    expect( @user.reload).to be_share_address
    expect( @user).to be_share_mobile_phone
    expect( @user).to be_share_home_phone
    expect(@user).to_not be_share_work_phone
    expect(@user).to_not be_share_fax
    expect( @user).to be_share_email
    expect(@user).to_not be_share_birthday
    expect(@user).to_not be_share_anniversary
    expect(@user).to_not be_share_activity
  end

end
