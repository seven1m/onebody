require File.dirname(__FILE__) + '/../test_helper'

class BlogsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
  end
  
  should "show 25 blog items" do
    @person.forge_blog
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 25, assigns(:blog_items).length
  end
  
  should "not show the blog if the logged in user cannot see the person" do
    @person.update_attribute :visible, false
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show any deleted blog items" do
    @person.forge_blog
    @person.notes.destroy_all
    get :show, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 0, assigns(:blog_items).select { |o| o.is_a? Note }.length
  end
  
end
