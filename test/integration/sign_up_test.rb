require "#{File.dirname(__FILE__)}/../test_helper"

class SignUpTest < ActionController::IntegrationTest
  fixtures :people, :families

  def test_verify_email
    get '/account/verify_email'
    assert_response :success
    assert_template 'account/verify_email'
    post '/account/verify_email', :email => people(:peter).email
    assert_response :success
    assert_select 'body', /email has been sent/
    v = Verification.find(:first, :order => 'id desc')
    assert_equal people(:peter).email, v.email
    assert !v.code.nil?
    assert v.code > 0
    assert_select_email do
      assert_select '', Regexp.new("http://[a-zA-Z\-\.]/account/verify_code?id=#{v.id}&code=#{v.code}")
    end
    verify_code(v, people(:peter))
  end
  
  def test_verify_mobile
    get '/account/verify_mobile'
    assert_response :success
    assert_template 'account/verify_mobile'
    post '/account/verify_mobile', :mobile => people(:peter).mobile_phone, :carrier => 'Cingular'
    v = Verification.find(:first, :order => 'id desc')
    assert !v.code.nil?
    assert v.code > 0
    assert_select_email do
      assert_select '', Regexp.new(v.code.to_s)
    end
    assert_redirected_to :action => 'verify_code', :id => v.id
    follow_redirect!
    assert_select 'div#notice', /message has been sent/
    assert_equal people(:peter).mobile_phone, v.mobile_phone
    verify_code(v, people(:peter))
  end
  
  def verify_code(v, person)
    get '/account/verify_code', :id => v.id, :code => v.code
    assert_redirected_to :action => 'edit', :id => person.id
    follow_redirect!
    assert_response :success
    assert_template 'account/edit'
    assert_select 'div#notice', /set your personal email address/
    post '/account/edit', :id => person.id, :person => {:email => person.email, :password => 'secret', :password_confirmation => 'secret'}
    assert_redirected_to :controller => 'people', :action => 'view', :id => person.id
  end
end
