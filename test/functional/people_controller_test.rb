require File.dirname(__FILE__) + '/../test_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL)

class PeopleControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @limited_person = Person.forge(:full_access => false)
  end

  should "redirect the index action to the currently logged in person" do
    get :index, nil, {:logged_in_id => @person.id}
    assert_redirected_to :action => 'show', :id => @person.id
  end

  should "show a person" do
    get :show, {:id => @person.id}, {:logged_in_id => @person.id} # myself
    assert_response :success
    assert_template 'show'
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id} # someone else
    assert_response :success
    assert_template 'show'
  end

  should "show a limited view of a person" do
    get :show, {:id => @person.id}, {:logged_in_id => @limited_person.id}
    assert_response :success
    assert_template 'show_limited'
  end

  should "show a simple view" do
    get :show, {:id => @person.id, :simple => true}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'show_simple'
  end

  should "show a simple photo view" do
    get :show, {:id => @person.id, :simple => true, :photo => true}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'show_simple_photo'
  end

  should "not show a simple view to limited users" do
    get :show, {:id => @person.id, :simple => true}, {:logged_in_id => @limited_person.id}
    assert_response :missing
  end

  should "not show a simple photo view to limited users" do
    get :show, {:id => @person.id, :simple => true, :photo => true}, {:logged_in_id => @limited_person.id}
    assert_response :missing
  end

  should "not show a person if they are invisible to the logged in user" do
    @person.update_attribute :visible, false
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end

  should "create a person update" do
    first_name = @person.first_name
    get :edit, {:id => @person.id}, {:logged_in_id => @person.id}
    assert_response :success
    post :update,
      {
        :id => @person.id,
        :person => {
          :family_id => @person.family_id, # should be ignored
          :first_name => 'Bob',
          :last_name => 'Smith'
        },
        :family => {
          :name => 'Bob Smith',
          :last_name => 'Smith'
        }
      },
      {:logged_in_id => @person.id}
    assert_redirected_to edit_person_path(@person)
    assert_equal first_name, @person.reload.first_name
    assert_equal 1, @person.updates.count
  end

  should "edit favorites and other non-basic person information" do
    testimony = Faker::Lorem.paragraph; interests = Faker::Lorem.paragraph
    post :update,
      {
        :id => @person.id,
        :person => {
          :testimony => testimony,
          :interests => interests
        }
      },
      {:logged_in_id => @person.id}
    assert_redirected_to edit_person_path(@person)
    assert_equal testimony, @person.reload.testimony
    assert_equal interests, @person.interests
    assert_equal 0, @person.updates.count
  end

  should "edit a person basics when user is admin" do
    @other_person.admin = Admin.create!(:edit_profiles => true)
    @other_person.save!
    post :update,
      {
        :id => @person.id,
        :person => {
          :first_name => 'Bob',
          :last_name => 'Smith'
        },
        :family => {
          :name => 'Bob Smith',
          :last_name => 'Smith'
        }
      },
      {:logged_in_id => @other_person.id}
    assert_redirected_to edit_person_path(@person)
    assert_equal 'Bob', @person.reload.first_name
    assert_equal 0, @person.updates.count
  end

  should "delete a person" do
    @other_person.admin = Admin.create!(:edit_profiles => true)
    @other_person.save!
    post :destroy, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert @person.reload.deleted?
  end

  should "not delete self" do
    @person.admin = Admin.create!(:edit_profiles => true)
    @person.save!
    post :destroy, {:id => @person.id}, {:logged_in_id => @person.id}
    assert_response :unauthorized
    assert !@person.reload.deleted?
  end

  should "not delete a person unless admin" do
    post :destroy, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
    post :destroy, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end

  should "freeze an account" do
    @other_person.admin = Admin.create!(:edit_profiles => true)
    @other_person.save!
    post :update, {:id => @person.id, :freeze => 'toggle'}, {:logged_in_id => @other_person.id}
    assert_response :redirect
    assert @person.reload.account_frozen?
    post :update, {:id => @person.id, :freeze => 'toggle'}, {:logged_in_id => @other_person.id}
    assert_response :redirect
    assert !@person.reload.account_frozen?
  end

  should "not freeze self" do
    @person.admin = Admin.create!(:edit_profiles => true)
    @person.save!
    post :update, {:id => @person.id, :freeze => 'toggle'}, {:logged_in_id => @person.id}
    assert_select 'body', /cannot freeze your own account/i
    assert !@person.reload.account_frozen?
  end

  should "not show xml unless user can export data" do
    get :show, {:id => @person.id, :format => 'xml'}, {:logged_in_id => @person.id}
    assert_response 406
  end

  should "show xml for admin who can export data" do
    @other_person.admin = Admin.create!(:export_data => true)
    @other_person.save!
    get :show, {:id => @person.id, :format => 'xml'}, {:logged_in_id => @other_person.id}
    assert_response :success
  end

  should "show business listing" do
    people(:tim).update_attributes!(:business_name => 'Tim Morgan Enterprises')
    get :show, {:id => people(:tim).id}, {:logged_in_id => people(:tim).id}
    assert_response :success
    assert_select 'body', /Tim Morgan Enterprises/
  end

  should "not allow creation of people if the site has reached limit" do
    @family = Family.forge
    @admin = Person.forge(:admin => Admin.create(:edit_profiles => true))
    Site.current.update_attribute(:max_people, 1000)
    post :create, {:person => {:first_name => 'John', :last_name => 'Smith', :family_id => @family.id, :child => false}}, {:logged_in_id => @admin.id}
    assert_response :redirect
    Site.current.update_attribute(:max_people, 1)
    post :create, {:person => {:first_name => 'John', :last_name => 'Doe',   :family_id => @family.id, :child => false}}, {:logged_in_id => @admin.id}
    assert_response :unauthorized
    Site.current.update_attribute(:max_people, nil)
    post :create, {:person => {:first_name => 'Jane', :last_name => 'Smith', :family_id => @family.id, :child => false}}, {:logged_in_id => @admin.id}
    assert_response :redirect
  end

  should "not allow deletion of a global super admin" do
     @super_admin = Person.forge(:admin => Admin.create(:super_admin => true))
     @global_super_admin = Person.forge(:email => 'support@example.com')
     post :destroy, {:id => @global_super_admin.id}, {:logged_in_id => @super_admin.id}
     assert_response :unauthorized
  end
end
