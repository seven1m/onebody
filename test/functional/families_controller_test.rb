require_relative '../test_helper'

class FamiliesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @family = @person.family
    @child = FactoryGirl.create(:person, family: @family, birthday: 1.year.ago, gender: 'Female', child: nil)
    @admin = FactoryGirl.create(:person, admin: Admin.create(edit_profiles: true))
  end

  should "show a family" do
    get :show, {id: @family.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_template 'show'
    assert_equal @family, assigns(:family)
    assert_equal [@person, @child], assigns(:people)
  end

  should "not show hidden people in the family" do
    get :show, {id: @family.id}, {logged_in_id: @other_person.id}
    assert_response :success
    assert_template 'show'
    assert_equal @family, assigns(:family)
    assert_equal [@person], assigns(:people)
  end

  should "not show the family unless it is visible" do
    @family.update_attributes! visible: false
    get :show, {id: @family.id}, {logged_in_id: @other_person.id}
    assert_response :missing
  end

  should "create a new family" do
    get :new, nil, {logged_in_id: @admin.id}
    assert_response :success
    first_name = 'Mary'
    last_name = 'Jones'
    name = "#{first_name} #{last_name}"
    post :create,
      {family: {name: name, last_name: last_name, address1: '123 S Morgan st.', address2: '', city: 'Tulsa', state: 'OK', zip: '74120', home_phone: '123-456-7890'}},
      {logged_in_id: @admin.id}
    assert_response :redirect
  end

  should "not create a new family unless user is admin" do
    get :new, nil, {logged_in_id: @person.id}
    assert_response :unauthorized
    first_name = 'Mary'
    last_name = 'Jones'
    name = "#{first_name} #{last_name}"
    post :create,
      {family: {name: name, last_name: last_name, address1: '123 S Morgan st.', address2: '', city: 'Tulsa', state: 'OK', zip: '74120', home_phone: '123-456-7890'}},
      {logged_in_id: @person.id}
    assert_response :unauthorized
  end

  should "edit a family" do
    get :edit, {id: @family.id}, {logged_in_id: @admin.id}
    assert_response :success
    post :update,
      {id: @family.id, family: {name: @family.name, last_name: @family.last_name, address1: @family.address1, address2: @family.address2, city: @family.city, state: @family.state, zip: @family.zip, home_phone: @family.home_phone}},
      {logged_in_id: @admin.id}
    assert_response :redirect
  end

  should "not show xml unless user can export data" do
    get :show, {id: @family.id, format: 'xml'}, {logged_in_id: @person.id}
    assert_response 406
  end

  should "show xml for admin who can export data" do
    @other_person.admin = Admin.create!(export_data: true)
    @other_person.save!
    get :show, {id: @family.id, format: 'xml'}, {logged_in_id: @other_person.id}
    assert_response :success
  end

end
