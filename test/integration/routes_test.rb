require File.dirname(__FILE__) + '/../test_helper'

class RoutesTest < ActionController::IntegrationTest

  # I'm just going to test some of the oddballs here...

  should "route to news" do
    assert_routing '/news', :controller => 'news', :action => 'index'
    assert_routing '/news/1', :controller => 'news', :action => 'show', :id => '1'
    assert_equal '/news/1', news_item_path(1)
    assert_equal '/news', news_path
    assert_equal '/news', news_items_path
  end

  should "route to bible" do
    assert_recognizes({:controller => 'bibles', :action => 'show', :book => 'John', :chapter => '0'}, '/bible/John')
  end

  should "route to pages" do
    assert_recognizes({:controller => 'pages', :action => 'show_for_public', :path => 'home'}, '/pages/home')
  end

  should "route to admin dashboard" do
    assert_routing '/admin', :controller => 'administration/dashboards', :action => 'show'
  end

  should "route in the admin namespace" do
    assert_routing '/admin/admins', :controller => 'administration/admins', :action => 'index'
  end

  should "route to admin/files" do
    assert_routing '/admin/files', :controller => 'administration/files', :action => 'index'
    assert_routing '/admin/files/abc123_.abc123_', :controller => 'administration/files', :action => 'show', :id => 'abc123_.abc123_'
    post '/session', :email => people(:tim).email, :password => 'secret'
    assert_redirected_to stream_path
    get '/admin/files/thisis..evil' # route not recognized
    assert_response :missing
  end

end
