require File.dirname(__FILE__) + '/../test_helper'

class RemoteAccountsControllerTest < ActionController::TestCase
  
  # def setup
  #   @person, @other_person = Person.forge(:admin => Admin.create(:view_hidden_properties => true)), Person.forge
  #   @remote_account = @person.remote_accounts.create!(:account_type => 'highrise', :username => 'foo', :token => 'bar')
  # end
  # 
  # should "list all remote accounts" do
  #   get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
  #   assert_response :success
  #   assert_equal 1, assigns(:remote_accounts).length
  # end
  # 
  # should "not list remote accounts if user cannot edit person" do
  #   get :index, {:person_id => @person.id}, {:logged_in_id => @other_person.id}
  #   assert_response :unauthorized
  # end
  # 
  # should "not list remote accounts if user is not admin" do
  #   @person.update_attribute :admin_id, nil
  #   get :index, {:person_id => @person.id}, {:logged_in_id => @person.id}
  #   assert_response :unauthorized
  # end
  # 
  # should "create a new remote account" do
  #   @remote_account.destroy
  #   account_count = RemoteAccount.count
  #   get :new, {:person_id => @person.id}, {:logged_in_id => @person.id}
  #   assert_response :success
  #   post :create, {:person_id => @person.id, :remote_account => {:account_type => 'highrise', :username => 'foo', :token => 'bar'}}, {:logged_in_id => @person.id}
  #   assert_redirected_to person_remote_accounts_path(@person)
  #   assert_equal account_count+1, RemoteAccount.count
  # end
  # 
  # should "edit a remote account" do
  #   get :edit, {:person_id => @person.id, :id => @remote_account.id}, {:logged_in_id => @person.id}
  #   assert_response :success
  #   post :update, {:person_id => @person.id, :id => @remote_account.id, :remote_account => {:account_type => 'highrise', :username => 'foo new', :token => 'bar new'}}, {:logged_in_id => @person.id}
  #   assert_redirected_to person_remote_accounts_path(@person)
  #   assert_equal 'foo new', @remote_account.reload.username
  #   assert_equal 'bar new', @remote_account.token
  # end
  # 
  # should "delete a remote account" do
  #   post :destroy, {:person_id => @person.id, :id => @remote_account.id}, {:logged_in_id => @person.id}
  #   assert_redirected_to person_remote_accounts_path(@person)
  #   assert_raise(ActiveRecord::RecordNotFound) do
  #     @remote_account.reload
  #   end
  # end
  
end
