require "#{File.dirname(__FILE__)}/../test_helper"

class PrivacyTest < ActionController::IntegrationTest
  fixtures :people, :families
  
  def test_help_for_parents_with_hidden_children
    sign_in_as people(:jeremy)
    get '/people/index'
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar', /Where are my kids\?/
    assert_select '#sidebar a[href=?]', /\/help\/safeguarding_children/
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
  end
  
  def test_children_without_consent_hidden_on_family_profiles
    sign_in_as people(:peter)
    get "/people/view/#{people(:tim).id}" # view Tim's profile
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
  end
  
  def test_children_without_consent_profiles_hidden
    sign_in_as people(:peter)
    get "/people/view/#{people(:mac).id}" # view Mac's profile (child)
    assert_response :success
    assert_select 'body', /not authorized/
    assert_select 'body', :html => /mac/i, :count => 0
  end
  
  def test_children_without_consent_hidden_in_search_results
    sign_in_as people(:peter)
    get "/directory/search", :name => 'Mac'
    assert_template 'directory/search'
    assert_select 'body', /Your search didn't match any people\./
  end
  
  def test_name_attribute
    sign_in_as people(:peter)
    assert_equal '???', Person.find(people(:mac).id).name # do a full load because name is cached
    sign_in_as people(:tim)
    assert_equal 'Mac Morgan', Person.find(people(:mac).id).name # do a full load because name is cached
  end
  
  def test_children_cannot_sign_in_without_consent
    post_sign_in_form people(:mac).email
    assert_redirected_to '/help/unauthorized'
    people(:mac).update_attribute :parental_consent, 'consent statement goes here' # not nil means this child has consent
    sign_in_as people(:mac)  # sign_in_as() will do assertions
  end
  
  def test_parent_give_parental_consent
    sign_in_as people(:jeremy)
    get '/people/index'
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
    get '/people/privacy'
    assert_response :success
    assert_template 'people/privacy'
    assert_select 'p.alert', :minimum => 1, :text => /you have not given consent/
    assert_select 'li', :minimum => 1, :text => /Privacy Policy/
    assert_select 'input[type=submit][value=I Agree]', 1
    post "/people/privacy/#{people(:megan).id}", :agree => 'I Agree.'
    assert_redirected_to :controller => 'people', :action => 'privacy'
    follow_redirect!
    assert_select 'div#notice', /Agreement saved\./
    people(:megan).reload
    assert people(:megan).parental_consent # not nil
    assert people(:megan).parental_consent.include?("#{people(:jeremy).name} \(#{people(:jeremy).id}\)")
    assert_select 'p.highlight', :minimum => 1, :text => /This child's profile has parental consent/
    get '/people/index'
    assert_response :success
    assert_template 'people/view'
    assert_select '#sidebar tr.family-member', 3 # not 2 (should see child)
    assert_select '#sidebar tr.family-member', :minimum => 1, :text => Regexp.new(people(:megan).name)
  end
  
  def test_invisible_profiles
    people(:jane).update_attribute :visible, false
    sign_in_as people(:jeremy)
    assert_select '#sidebar tr.family-member', 0 # only 1 visible family member -- no people displayed when there's only 1
    sign_in_as people(:peter)
    get "/people/view/#{people(:jane).id}"
    assert_response :success
    assert_select 'body', /not authorized/
    assert_select 'body', :html => /jane/i, :count => 0
  end
end
