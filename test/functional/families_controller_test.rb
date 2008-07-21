require File.dirname(__FILE__) + '/../test_helper'

class FamiliesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    @family = @person.family
    @child = Person.forge(:family => @family, :birthday => 1.year.ago, :gender => 'Girl')
    @admin = Person.forge(:admin => Admin.create(:edit_profiles => true))
  end
  
  should "show a family" do
    get :show, {:id => @family.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_template 'show'
    assert_equal @family, assigns(:family)
    assert_equal [@person, @child], assigns(:people)
  end
  
  should "not show hidden people in the family" do
    get :show, {:id => @family.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'show'
    assert_equal @family, assigns(:family)
    assert_equal [@person], assigns(:people)
  end
  
  should "not show the family unless it is visible" do
    @family.update_attributes! :visible => false
    get :show, {:id => @family.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "create a new family" do
    get :new, nil, {:logged_in_id => @admin.id}
    assert_response :success
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    name = "#{first_name} #{last_name}"
    post :create,
      {:family => {:name => name, :last_name => last_name, :address1 => Faker::Address.street_address, :address2 => '', :city => Faker::Address.city, :state => Faker::Address.us_state, :zip => Faker::Address.zip_code, :home_phone => Faker::PhoneNumber.phone_number}},
      {:logged_in_id => @admin.id}
    assert_response :redirect
  end
  
  should "not create a new family unless user is admin" do
    get :new, nil, {:logged_in_id => @person.id}
    assert_response :unauthorized
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    name = "#{first_name} #{last_name}"
    post :create,
      {:family => {:name => name, :last_name => last_name, :address1 => Faker::Address.street_address, :address2 => '', :city => Faker::Address.city, :state => Faker::Address.us_state, :zip => Faker::Address.zip_code, :home_phone => Faker::PhoneNumber.phone_number}},
      {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
  should "edit a family" do
    get :edit, {:id => @family.id}, {:logged_in_id => @admin.id}
    assert_response :success
    post :update,
      {:id => @family.id, :family => {:name => @family.name, :last_name => @family.last_name, :address1 => @family.address1, :address2 => @family.address2, :city => @family.city, :state => @family.state, :zip => @family.zip, :home_phone => @family.home_phone}},
      {:logged_in_id => @admin.id}
    assert_response :redirect
  end
  
  should "only allow adult family members and admins to edit a family"
  
  should "add a person to a family"
  
  should "remove a person from a family"

end
