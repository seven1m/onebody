require "#{File.dirname(__FILE__)}/../test_helper"

class PrivacyTest < ActionController::IntegrationTest
  setup do
    @user = FactoryGirl.create(:person)
    @head = FactoryGirl.create(:person)
    @spouse = FactoryGirl.create(:person, family: @head.family, first_name: 'Jane')
  end

  context 'given a child without parental consent' do
    setup do
      @child = FactoryGirl.create(:person, family: @head.family, first_name: 'Megan', child: true)
    end

    context 'when viewed by a stranger' do
      setup do
        sign_in_as @user
      end

      should 'not show child on parent profile' do
        get "/people/#{@head.id}"
        assert_response :success
        assert_template 'people/show'
        assert_select '.family li', 2 # not 3 (should not see child)
        assert_no_match(/Megan/, response.body)
      end

      should 'not show profile page of child' do
        get "/people/#{@child.id}"
        assert_response :missing
      end

      should 'not show child in search results' do
        get "/search", name: 'Megan'
        assert_template 'searches/create'
        assert_select 'body', /0 people found/
      end
    end

    context 'when viewed by adult in same family' do
      setup do
        sign_in_as @head
      end

      should 'show child on parent profile' do
        get "/people/#{@head.id}"
        assert_response :success
        assert_template 'people/show'
        assert_select '.family li', 3
        assert_match(/Megan/, response.body)
      end

      should 'show profile page of child' do
        get "/people/#{@child.id}"
        assert_response :success
      end

      should 'not show child in search results' do
        get "/search", name: 'Megan'
        assert_template 'searches/create'
        assert_select 'body', /0 people found/
      end
    end

    should 'not allow child to sign in' do
      post_sign_in_form @child.email
      assert_redirected_to '/pages/system/unauthorized'
    end

    should 'give child parental consent from parent' do
      sign_in_as @head
      get "/people/#{@child.id}/privacy/edit"
      assert_response :success
      assert_template 'privacies/edit'
      assert_select 'body', minimum: 1, text: /you have not given consent/
      assert_select 'li', minimum: 1, text: /Privacy Policy/
      assert_select 'input[type=submit][value=I Agree]', 1
      put "/people/#{@child.id}/privacy", agree: 'I Agree.'
      assert_response :redirect
      follow_redirect!
      assert_template 'privacies/edit'
      assert_select 'div#notice', /Agreement saved\./
      @child.reload
      assert @child.parental_consent # not nil
      assert @child.parental_consent.include?("#{@head.name} \(#{@head.id}\)")
      assert_select 'body', minimum: 1, text: /profile has parental consent/
    end
  end

  context 'given child with parental consent' do
    setup do
      @child = FactoryGirl.create(:person, family: @head.family, first_name: 'Megan', child: true, parental_consent: 'consent')
    end

    should 'allow child to sign in' do
      sign_in_as @child
      assert_select '.left-sidebar h2', 'Your Homepage'
    end
  end

  #def test_invisible_profiles
    #people(:jane).update_attribute :visible, false
    #sign_in_as people(:jeremy)
    #assert_select '.family li', 0 # only 1 visible family member -- no people displayed when there's only 1
    #sign_in_as people(:peter)
    #get "/people/#{people(:jane).id}"
    #assert_response :missing
  #end
end
