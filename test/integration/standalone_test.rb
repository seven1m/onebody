require "#{File.dirname(__FILE__)}/../test_helper"

class StandaloneTest < ActionController::IntegrationTest
  fixtures :people, :families

  def test_cannot_edit_person
    sign_in_as people(:jeremy)
    get edit_profile_path(:id => people(:tim))
    assert_response :success
    assert_select 'body', /You may not edit/
  end
  
  def test_can_edit_person
    SETTINGS['features']['standalone_use'] = true
    edit_path = edit_profile_path(:id => people(:jeremy))
    sign_in_as people(:tim)
    get edit_path
    assert_response :success
    assert_template 'people/edit'
    assert_select 'body', /person_first_name/
    assert_select 'body', :html => /reviewed by church staff/, :count => 0
    post edit_path, :person => {:first_name => 'Jeremiah', :mobile_phone => '(111) 222-3333', :fax => '', :birthday => '12/1/1979', :anniversary => ''}, :family => {:home_phone => '(222) 333-4444'}
    assert_redirected_to edit_path
    follow_redirect!
    assert_select 'body', /changes saved/i
    assert_equal 'Jeremiah', people(:jeremy).reload.first_name
    assert_equal 1112223333, people(:jeremy).mobile_phone
    assert_equal nil, people(:jeremy).fax
    assert_equal '12/01/1979', people(:jeremy).birthday.to_s(:date)
    assert_equal nil, people(:jeremy).anniversary
    assert_equal 2223334444, people(:jeremy).family.reload.home_phone
  end
  
  def test_cannot_edit_person_but_can_submit_changes
    SETTINGS['features']['standalone_use'] = false
    edit_path = edit_profile_path(:id => people(:jeremy))
    sign_in_as people(:jeremy)
    get edit_path
    assert_response :success
    assert_template 'people/edit'
    assert_select 'body', /person_first_name/
    assert_select 'body', /reviewed by church staff/
    phone_was = people(:jeremy).mobile_phone
    family_phone_was = people(:jeremy).family.home_phone
    update_count_was = Update.count
    post edit_path, :person => {:mobile_phone => '(222) 333-4444'}, :family => {:home_phone => '(333) 444-5555'}
    assert_redirected_to edit_path
    follow_redirect!
    assert_select 'body', /changes saved/i
    assert_equal update_count_was + 1, Update.count
    assert_equal phone_was, people(:jeremy).reload.mobile_phone
    assert_equal family_phone_was, people(:jeremy).family.reload.home_phone
  end
  
end
