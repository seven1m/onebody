require File.dirname(__FILE__) + '/../test_helper'

class PagesControllerTest < ActionController::TestCase

  def setup
    Setting.set(1, 'Features', 'Content Management System', true)
    @admin = Person.forge(:admin => Admin.create(:edit_pages => true))
    @person = Person.forge
  end
  
  should "show the root page by default" do
    get :show_for_public
    assert_response :success
    assert_equal pages(:home), assigns(:page)
    get :show_for_public, {:path => ''}
    assert_response :success
    assert_equal pages(:home), assigns(:page)
  end
  
  should "show a top level page based on path" do
    get :show_for_public, {:path => 'foo'}
    assert_response :success
    assert_equal pages(:foo), assigns(:page)
  end
  
  should "show a child level page based on path" do
    get :show_for_public, {:path => 'foo/baz'}
    assert_response :success
    assert_equal pages(:baz), assigns(:page)
  end
  
  should "not show a page if it does not exist" do
    get :show_for_public, {:path => 'foo/bar'}
    assert_response :missing
  end
  
  should "show breadcrumb trail on non-root pages" do
    get :show_for_public, {:path => 'foo/baz'}
    assert_tag 'p', :content => /Foo/, :attributes => {:id => 'breadcrumbs'}
  end
  
  should "not show a page if it is not published" do
    pages(:foo).update_attribute(:published, false)
    get :show_for_public, {:path => 'foo'}
    assert_response :missing
  end
  
  # admin actions...
  
  should "show a page for admin" do
    get :show, {:id => pages(:baz).id}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_tag 'span', :content => /edit/
  end
  
  should "not show a page for admin unless user is admin" do
    get :show, {:id => pages(:baz).id}, {:logged_in_id => @person.id}
    assert_redirected_to page_for_public_path(:path => pages(:baz).path)
  end
  
  should "show a listing of pages underneath the specified parent" do
    get :index, nil, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal 3, assigns(:pages).length
    get :index, {:parent_id => pages(:foo).id}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal 1, assigns(:pages).length
    assert_equal pages(:baz), assigns(:pages).first
  end
  
  should "show new page form" do
    get :new, nil, {:logged_in_id => @admin.id}
    assert_response :success
    assert assigns(:page)
  end
  
  should "create a new root page" do
    post :create, {:page => {:title => 'Test', :slug => 'test', :body => 'the body'}}, {:logged_in_id => @admin.id}
    @new_page = Page.last
    assert_redirected_to page_path(@new_page)
    assert_match /saved/, flash[:notice]
    assert_equal 'Test',     @new_page.title
    assert_equal 'test',     @new_page.slug
    assert_equal 'the body', @new_page.body
  end
  
  should "create a new sub page" do
    post :create, {:page => {:title => 'Test', :slug => 'test', :body => 'the body', :parent_id => pages(:foo).id}}, {:logged_in_id => @admin.id}
    assert_redirected_to page_path(Page.last)
    assert_match /saved/, flash[:notice]
  end
  
  should "not create a new page unless user is admin" do
    get :new, nil, {:logged_in_id => @person.id}
    assert_response :unauthorized
    post :create, {:page => {:title => 'Test', :slug => 'test', :body => 'the body'}}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
  should "show edit page form" do
    get :edit, {:id => pages(:baz).id}, {:logged_in_id => @admin.id}
    assert_response :success
    assert_equal pages(:baz), assigns(:page)
  end
  
  should "update a page" do
    post :update, {:id => pages(:baz).id, :page => {:title => 'Test', :slug => 'test', :body => 'the body'}}, {:logged_in_id => @admin.id}
    assert_redirected_to page_path(pages(:baz))
    assert_match /saved/, flash[:notice]
    assert_equal 'Test',     pages(:baz).reload.title
    assert_equal 'test',     pages(:baz).slug
    assert_equal 'the body', pages(:baz).body
  end
  
  should "not edit a page unless user is admin" do
    get :edit, {:id => pages(:baz).id}, {:logged_in_id => @person.id}
    assert_response :unauthorized
    post :update, {:id => pages(:baz).id, :page => {:title => 'Test', :slug => 'test', :body => 'the body'}}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end
  
  should "delete a page" do
    post :destroy, {:id => pages(:baz).id}, {:logged_in_id => @admin.id}
    assert_redirected_to pages_path
    assert_raise(ActiveRecord::RecordNotFound) do
      pages(:baz).reload
    end
  end
  
  should "not delete a page unless user is admin" do
    post :destroy, {:id => pages(:baz).id}, {:logged_in_id => @person.id}
    assert_response :unauthorized
  end

end
