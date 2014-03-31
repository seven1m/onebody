require_relative '../test_helper'

class PagesControllerTest < ActionController::TestCase

  fixtures :pages

  def setup
    @admin = FactoryGirl.create(:person, admin: Admin.create(edit_pages: true))
    @person = FactoryGirl.create(:person)
  end

  should "show a top level page based on path" do
    get :show_for_public, {path: 'foo'}
    assert_response :success
    assert_equal pages(:foo), assigns(:page)
  end

  should "show a child level page based on path" do
    get :show_for_public, {path: 'foo/baz'}
    assert_response :success
    assert_equal pages(:baz), assigns(:page)
  end

  should "not show a page if it does not exist" do
    get :show_for_public, {path: 'foo/bar'}
    assert_response :redirect
  end

  should "not show a page if it is not published" do
    pages(:foo).update_attribute(:published, false)
    get :show_for_public, {path: 'foo'}
    assert_response :missing
  end

  # admin actions...

  should "show edit page form" do
    get :edit, {id: pages(:baz).id}, {logged_in_id: @admin.id}
    assert_response :success
    assert_equal pages(:baz), assigns(:page)
  end

  should "update a page" do
    post :update, {id: pages(:baz).id, page: {title: 'Test', slug: 'test', body: 'the body'}}, {logged_in_id: @admin.id}
    assert_redirected_to pages_path
    assert_match /saved/, flash[:notice]
    assert_equal 'Test',     pages(:baz).reload.title
    assert_equal 'test',     pages(:baz).slug
    assert_equal 'the body', pages(:baz).body
  end

  should "not edit a page unless user is admin" do
    get :edit, {id: pages(:baz).id}, {logged_in_id: @person.id}
    assert_response :unauthorized
    post :update, {id: pages(:baz).id, page: {title: 'Test', slug: 'test', body: 'the body'}}, {logged_in_id: @person.id}
    assert_response :unauthorized
  end

end
