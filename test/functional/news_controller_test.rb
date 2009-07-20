require File.dirname(__FILE__) + '/../test_helper'

class NewsControllerTest < ActionController::TestCase
  
  def setup
    @person = Person.forge
    @news_item = NewsItem.forge
  end
  
  should "list all items by js" do
    get :index, nil, {:logged_in_id => @person}
    assert_response :success
    assert_equal 2, assigns(:news_items).length # 1 item already in news_items.yml
  end
  
end
