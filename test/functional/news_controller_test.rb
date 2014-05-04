require_relative '../test_helper'

class NewsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @news_item = FactoryGirl.create(:news_item)
  end

  should "list all items by js" do
    get :index, nil, {logged_in_id: @person.id}
    assert_response :success
    assert_equal 1, assigns(:news_items).length
  end

end
