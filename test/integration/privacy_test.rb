require "#{File.dirname(__FILE__)}/../test_helper"

class PrivacyTest < ActionController::IntegrationTest
  fixtures :people, :families
  
  def test_help_for_parents_with_hidden_children
    sign_in_as people(:jeremy)
    assert_select '#sidebar', /Where are my kids\?/
    assert_select '#sidebar a[href=?]', /\/help\/safeguarding_children/
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
  end
  
  def test_children_without_consent_hidden_on_family_profiles
    sign_in_as people(:peter)
    get "/people/#{people(:tim).id}" # view Tim's profile
    assert_response :success
    assert_template 'people/show'
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
  end
  
  def test_children_without_consent_profiles_hidden
    sign_in_as people(:peter)
    get "/people/#{people(:mac).id}" # view Mac's profile (child)
    assert_response :missing
  end
  
  def test_children_without_consent_hidden_in_search_results
    sign_in_as people(:peter)
    get "/search", :name => 'Mac'
    assert_template 'searches/new'
    assert_select 'body', /Your search didn't match any people\./
  end
  
  def test_children_cannot_sign_in_without_consent
    post_sign_in_form people(:mac).email
    assert_redirected_to '/help/unauthorized'
    people(:mac).update_attribute :parental_consent, 'consent statement goes here' # not nil means this child has consent
    sign_in_as people(:mac)  # sign_in_as() will do assertions
  end
  
  def test_parent_give_parental_consent
    sign_in_as people(:jeremy)
    get '/'
    assert_response :redirect
    follow_redirect!
    assert_template 'people/show'
    assert_select '#sidebar tr.family-member', 2 # not 3 (should not see child)
    get "people/#{people(:jeremy).id}/privacy/edit"
    assert_response :success
    assert_template 'privacies/edit'
    assert_select 'p.alert', :minimum => 1, :text => /you have not given consent/
    assert_select 'li', :minimum => 1, :text => /Privacy Policy/
    assert_select 'input[type=submit][value=I Agree]', 1
    put "/people/#{people(:megan).id}/privacy", :agree => 'I Agree.'
    assert_response :redirect
    follow_redirect!
    assert_template 'privacies/edit'
    assert_select 'div#notice', /Agreement saved\./
    people(:megan).reload
    assert people(:megan).parental_consent # not nil
    assert people(:megan).parental_consent.include?("#{people(:jeremy).name} \(#{people(:jeremy).id}\)")
    assert_select 'p.highlight', :minimum => 1, :text => /This child's profile has parental consent/
    get "/people/#{people(:megan).id}"
    assert_response :success
    assert_template 'people/show'
    assert_select '#sidebar tr.family-member', 3 # not 2 (should see child)
    assert_select '#sidebar tr.family-member', :minimum => 1, :text => Regexp.new(people(:megan).name)
  end
  
  def test_invisible_profiles
    people(:jane).update_attribute :visible, false
    sign_in_as people(:jeremy)
    assert_select '#sidebar tr.family-member', 0 # only 1 visible family member -- no people displayed when there's only 1
    sign_in_as people(:peter)
    get "/people/#{people(:jane).id}"
    assert_response :missing
  end
end
