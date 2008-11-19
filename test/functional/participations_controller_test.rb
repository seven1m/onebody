require File.dirname(__FILE__) + '/../test_helper'

class ParticipationsControllerTest < ActionController::TestCase
  def setup
    @person = Person.forge
    @participation_category_choir = ParticipationCategory.create(:name => 'Choir')
    @participation_category_sunday_school = ParticipationCategory.create(:name => 'Sunday School')
    @person.participations.create :participation_category => @participation_category_sunday_school, :status => "current"
  end
  
  should "add participation to person" do
    post :create, {:receiving_element => 'current', :person_id => @person.id, :participation_category_id => @participation_category_choir.id, :format => 'js'}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 2, @person.participations.current.size
    assert_equal @person, assigns(:participation).person
    assert_equal @participation_category_choir, assigns(:participation).participation_category
    assert !assigns(:participation).new_record?
  end

  should "delete participation from person" do
    assert_equal 1, @person.participations.current.size
    post :destroy, {:id => 0, :person_id => @person.id, :participation_category_id => @participation_category_sunday_school.id, :format => 'js'}, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 0, @person.participations.current.size
  end
end