require_relative '../test_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL == 'support@example.com'

class PeopleControllerTest < ActionController::TestCase
  fixtures :people

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @limited_person = FactoryGirl.create(:person, full_access: false)
  end

  should "redirect the index action to the currently logged in person" do
    get :index, nil, {logged_in_id: @person.id}
    assert_redirected_to action: 'show', id: @person.id
  end

  should "show a person" do
    get :show, {id: @person.id}, {logged_in_id: @person.id} # myself
    assert_response :success
    assert_template 'show'
    get :show, {id: @person.id}, {logged_in_id: @other_person.id} # someone else
    assert_response :success
    assert_template 'show'
  end

  should "show a limited view of a person" do
    get :show, {id: @person.id}, {logged_in_id: @limited_person.id}
    assert_response :success
    assert_template 'show_limited'
  end

  should "not show a person if they are invisible to the logged in user" do
    @person.update_attribute :visible, false
    get :show, {id: @person.id}, {logged_in_id: @other_person.id}
    assert_response :missing
  end

  should "create a person update" do
    get :edit, {id: @person.id}, {logged_in_id: @person.id}
    assert_response :success
    post :update,
      {
        id: @person.id,
        person: {
          first_name: 'Bob',
          last_name: 'Smith'
        },
        family: {
          name: 'Bob Smith',
          last_name: 'Smith'
        }
      },
      {logged_in_id: @person.id}
    assert_redirected_to person_path(@person)
    assert_equal 'John', @person.reload.first_name # no change
    assert_equal 1, @person.updates.count
  end

  should "edit favorites and other non-basic person information" do
    post :update,
      {
        id: @person.id,
        person: {
          testimony: 'testimony',
          interests: 'interests'
        }
      },
      {logged_in_id: @person.id}
    assert_redirected_to person_path(@person)
    assert_equal 'testimony', @person.reload.testimony
    assert_equal 'interests', @person.interests
    assert_equal 0, @person.updates.count
  end

  should "edit a person basics when user is admin" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    post :update,
      {
        id: @person.id,
        person: {
          first_name: 'Bob',
          last_name: 'Smith'
        },
        family: {
          name: 'Bob Smith',
          last_name: 'Smith'
        }
      },
      {logged_in_id: @other_person.id}
    assert_redirected_to person_path(@person)
    assert_equal 'Bob', @person.reload.first_name
    assert_equal 0, @person.updates.count
  end

  should "create a person" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    @family = @person.family
    post :create,
      {
        person: {
          first_name: 'Todd',
          last_name: 'Jones',
          family_id: @family.id,
          child: '0'
        }
      },
      {logged_in_id: @other_person.id}
    assert_redirected_to family_path(@family)
    assert @family.people.find_by_first_name('Todd')
  end

  should "delete a person" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    assert @person.reload.deleted?
  end

  should "not delete self" do
    @person.admin = Admin.create!(edit_profiles: true)
    @person.save!
    post :destroy, {id: @person.id}, {logged_in_id: @person.id}
    assert_response :unauthorized
    assert !@person.reload.deleted?
  end

  should "not delete a person unless admin" do
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "not show xml unless user can export data" do
    get :show, {id: @person.id, format: 'xml'}, {logged_in_id: @person.id}
    assert_response 406
  end

  should "show xml for admin who can export data" do
    @other_person.admin = Admin.create!(export_data: true)
    @other_person.save!
    get :show, {id: @person.id, format: 'xml'}, {logged_in_id: @other_person.id}
    assert_response :success
  end

  should "show business listing" do
    people(:tim).update_attributes!(business_name: 'Tim Morgan Enterprises')
    get :show, {id: people(:tim).id, business: true}, {logged_in_id: people(:tim).id}
    assert_response :success
    assert_select 'body', /Tim Morgan Enterprises/
  end

  should "not allow deletion of a global super admin" do
     @super_admin = FactoryGirl.create(:person, admin: Admin.create(super_admin: true))
     @global_super_admin = FactoryGirl.create(:person, email: 'support@example.com')
     post :destroy, {id: @global_super_admin.id}, {logged_in_id: @super_admin.id}
     assert_response :unauthorized
  end

  should "not error when viewing a person not in a family" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(view_hidden_profiles: true))
    @person = Person.create!(first_name: 'Deanna', last_name: 'Troi', child: false, visible_to_everyone: true)
    # normal person should not see
    assert_nothing_raised do
      get :show, {id: @person.id}, {logged_in_id: @other_person.id}
    end
    assert_response :missing
    # admin should see a message
    assert_nothing_raised do
      get :show, {id: @person.id}, {logged_in_id: @admin.id}
    end
    assert_response :success
    assert_select 'div.alert', I18n.t('people.no_family_for_this_person')
  end
end
