require File.dirname(__FILE__) + '/../test_helper'

class BlogsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    @person.forge_blog
  end
  
  should "show 25 blog items separated by pictures and non-pictures" do
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 25, assigns(:pictures).length + assigns(:non_pictures).length
  end
  
  should "not show the blog if the logged in user cannot see the person" do
    @person.update_attribute :visible, false
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show any deleted blog items" do
    @person.notes.destroy_all
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 0, assigns(:non_pictures).select { |o| o.is_a? Note }.length
  end
  
end
