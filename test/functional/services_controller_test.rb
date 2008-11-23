require File.dirname(__FILE__) + '/../test_helper'

class ServicesControllerTest < ActionController::TestCase
  def setup
    @person = Person.forge
    @service_category_choir = ServiceCategory.create(:name => 'Choir')
    @service_category_sunday_school = ServiceCategory.create(:name => 'Sunday School')
    @person.services.create :service_category => @service_category_sunday_school, :status => "current"
  end
  
  should "add service to person" do
    post :create, {:receiving_element => 'current', :person_id => @person.id, :service_category_id => @service_category_choir.id, :format => 'js'}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 2, @person.services.current.size
    assert_equal @person, assigns(:service).person
    assert_equal @service_category_choir, assigns(:service).service_category
    assert !assigns(:service).new_record?
  end

  should "delete service from person" do
    assert_equal 1, @person.services.current.size
    post :destroy, {:id => 0, :person_id => @person.id, :service_category_id => @service_category_sunday_school.id, :format => 'js'}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 0, @person.services.current.size
  end
end