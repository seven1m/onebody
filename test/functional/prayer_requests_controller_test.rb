require_relative '../test_helper'

class PrayerRequestsControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = FactoryGirl.create(:group)
    @group.memberships.create(person_id: @person.id)
    @prayer_request = FactoryGirl.create(:prayer_request, group: @group, person: @person)
  end

  should "list all prayer requests" do
    get :index, {group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal 1, assigns(:reqs).length
  end

  should "list all answered prayer requests" do
    @unanswered = FactoryGirl.create(:prayer_request, group: @group, answer: nil, person: @person)
    get :index, {answered: true, group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal 1, assigns(:reqs).length
  end

  should "show a prayer request" do
    get :show, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
  end

  should "not show a prayer request if the user is not a member of the group" do
    get :show, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @other_person.id}
    assert_response :missing
  end

  should "create a prayer request" do
    get :new, {group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    post :create, {group_id: @group.id, prayer_request: {request: 'test req', answer: 'test answer', answered_at: '1/1/2010'}}, {logged_in_id: @person.id}
    assert_response :redirect
    new_req = PrayerRequest.last
    assert_equal 'test req',    new_req.request
    assert_equal 'test answer', new_req.answer
    assert_equal '01/01/2010',  new_req.answered_at.strftime('%m/%d/%Y')
  end

  should "not create a prayer request if the user is not a member of the group" do
    get :new, {group_id: @group.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
    post :create, {group_id: @group.id, prayer_request: {request: 'test req', answer: 'test answer', answered_at: '1/1/2010'}}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "edit a prayer request" do
    get :edit, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    post :update, {id: @prayer_request.id, group_id: @group.id, prayer_request: {request: 'test req', answer: 'test answer', answered_at: '1/1/2010'}}, {logged_in_id: @person.id}
    assert_response :redirect
    assert_equal 'test req',    @prayer_request.reload.request
    assert_equal 'test answer', @prayer_request.answer
    assert_equal '01/01/2010',  @prayer_request.answered_at.strftime('%m/%d/%Y')
  end

  should "not edit a prayer request if the user is not a member of the group" do
    get :edit, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
    post :update, {id: @prayer_request.id, group_id: @group.id, prayer_request: {request: 'test req', answer: 'test answer', answered_at: '1/1/2010'}}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "delete a prayer request" do
    post :destroy, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @person.id}
    assert_response :redirect
    assert_raise(ActiveRecord::RecordNotFound) do
      @prayer_request.reload
    end
  end

  should "not delete a prayer request if the user is not a member of the group" do
    post :destroy, {id: @prayer_request.id, group_id: @group.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

end
