require File.dirname(__FILE__) + '/../test_helper'
require 'comatose/admin_controller'
require 'text_filters'

# Re-raise errors caught by the controller.
class ComatoseAdminController < Comatose::AdminController
  def rescue_action(e) raise e end
end

class ComatoseAdminControllerTest < Test::Unit::TestCase

  fixtures :comatose_pages
    
  def setup
    @controller = ComatoseAdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  should "show the index action" do
    get :index
    assert_response :success
    assert assigns(:root_pages)
  end
  
  should "show the new action" do
    get :new
    assert_response :success
    assert assigns(:page)
  end
  
  should "successfully create pages" do
    post :new, :page=>{:title=>"Test page", :body=>'This is a *test*', :parent_id=>1, :filter_type=>'Textile'}
    assert_response :redirect
    assert_redirected_to :controller=>'comatose_admin', :action=>'index'
  end
  
  should "create a page with an empty body" do
    post :new, :page=>{:title=>"Test page", :body=>nil, :parent_id=>1, :filter_type=>'Textile'}
    assert_response :redirect
    assert_redirected_to :controller=>'comatose_admin', :action=>'index'
  end
  
  should "not create a page with a missing title" do
    post :new, :page=>{:title=>nil, :body=>'This is a *test*', :parent_id=>1, :filter_type=>'Textile'}
    assert_response :success
    assert assigns.has_key?('page'), "Page assignment"
    assert (assigns['page'].errors.length > 0), "Page errors"
    assert_equal 'must be present', assigns['page'].errors.on('title')
  end
  
  should "not create a page associated to an invalid parent" do
    post :new, :page=>{:title=>'Test page', :body=>'This is a *test*', :parent_id=>nil, :filter_type=>'Textile'}
    assert_response :success
    assert assigns.has_key?('page'), "Page assignment"
    assert (assigns['page'].errors.length > 0), "Page errors"
    assert_equal 'must be present', assigns['page'].errors.on('parent_id')
  end
  
  should "contain all the correct options for filter_type" do
    get :new
    assert_response :success
    assert_select 'SELECT[id=page_filter_type]>*', :count=>TextFilters.all_titles.length
  end
  
  should "show the edit action" do
    get :edit, :id=>1
    assert_response :success
  end
  
  should "update pages with valid data" do
    post :edit, :id=>1, :page=>{ :title=>'A new title' }
    assert_response :redirect
    assert_redirected_to :action=>"index"
  end
  
  should "not update pages with invalid data" do
    post :edit, :id=>1, :page=>{ :title=>nil }
    assert_response :success
    assert_equal 'must be present', assigns['page'].errors.on('title')
  end

  should "delete a page" do
    post :delete, :id=>1
    assert_response :redirect
    assert_redirected_to :action=>"index"
  end

  should "reorder pages" do
    q1 = comatose_page :question_one
    assert_not_nil q1
    assert_difference q1, :position do
      post :reorder, :id=>q1.parent.id, :page=>q1.id, :cmd=>'down'
      assert_response :redirect
      assert_redirected_to :action=>"reorder"
      q1.reload
    end
  end
  
  should "set runtime mode" do
    assert_equal :plugin, ComatoseAdminController.runtime_mode
    comatose_admin_view_path = File.expand_path(File.join( File.dirname(__FILE__), '..', '..', 'views'))

    if ComatoseAdminController.respond_to?(:template_root)
      assert_equal comatose_admin_view_path, ComatoseAdminController.template_root
    else
      assert ComatoseAdminController.view_paths.include?(comatose_admin_view_path)
    end
  end

end
