require "#{File.dirname(__FILE__)}/../test_helper"

class SignUpTest < ActionController::IntegrationTest
  #def test_sync
  #  if RAILS_PLATFORM =~ /win32/
  #    `ruby #{File.dirname(__FILE__)}..\..\script\sync test`
  #  else
  #    `#{File.dirname(__FILE__)}../../script/sync test`
  #  end
  #  
  #end
  
  #def test_verify_mobile
  #  get '/account/verify_mobile'
  #  assert_response :success
  #  assert_template 'account/verify_mobile'
  #end
  
  def test_truth
    assert true
  end
end
