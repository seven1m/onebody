require File.dirname(__FILE__) + '/../test_helper'

class NewsControllerTest < ActionController::TestCase
  
  def setup
    @person = Person.forge
    @news_item = NewsItem.forge
  end
  
  should "list all items by js" do
    get :index, nil, {:logged_in_id => @person}
    assert_response :success
    assert_equal 1, assigns(:news_items).length
    assert_equal 1, assigns(:headlines).length
  end
  
end
