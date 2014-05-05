require_relative '../test_helper'

class TagsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @tag = FactoryGirl.create(:tag)
  end

  should "show a tag by id" do
    get :show, {id: @tag.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal @tag, assigns(:tag)
  end

  should "show a tag by name" do
    get :show, {id: @tag.name}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal @tag, assigns(:tag)
  end

end
