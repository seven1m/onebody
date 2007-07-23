require "#{File.dirname(__FILE__)}/../test_helper"

class AdminsTest < ActionController::IntegrationTest
  fixtures :people, :families, :admins, :groups

  # def assert_edit(person, path, html, count)
  #     sign_in_as person
  #     get path
  #     assert_response :success
  #     assert_select '#subnav', :html => html, :count => count
  #   end
  #   
  #   def assert_edit_group(person, can_edit)
  #     assert_edit(person, '/groups/view/1', /edit group/i)
  #   end
  #   
  #   def assert_can_edit_group(person)
  #     assert_edit_group(person, true)
  #   end
  #   
  #   def assert_cannot_edit_group(person)
  #     assert_edit_group(person, false)
  #   end
  # 
  #   def test_group
  #     assert_can_edit_group people(:tim) # super admin
  #     assert_cannot_edit_group people(:jeremy) # not an admin
  #     people(:jeremy).admin = true
  #     assert_cannot_edit_group people(:jeremy) # admin, but cannot manage groups
  #     people(:jeremy).admin.update_attribute :manage_groups, true
  #     assert_can_edit_group people(:jeremy) # admin and can manage groups
  #   end
  #   
  #   def test_edit_profile
  #     sign_in_as people(:tim) # super admin
  #     get '/people/view/3'
  #     assert_response :success
  #     assert_template 'people/view'
  #     assert_select '#subnav', :html => /edit profile/i
  #   end
  
  def test_true
    assert true
  end
end
