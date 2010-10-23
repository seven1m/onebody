require "#{File.dirname(__FILE__)}/../test_helper"

class ClientTest < ActionController::IntegrationTest

  include WebratTestHelper

  context 'Search' do

    setup do
      sign_in_as people(:tim)
    end

    should 'search via ajax when the form is submitted' do
      visit '/search/new'
      fill_in :name_search, :with => 'Tim'
      selenium.click 'name=commit'
      selenium.wait_for_text I18n.t('search_results'), :timeout_in_seconds => 5
      assert_contain 'Tim Morgan'
      assert_match %r{/search/new$}, current_url # url didn't change
    end

    should 'search via ajax when form elements are changed' do
      visit '/search/new'
      fill_in :name_search, :with => 'Jeremy'
      selenium.wait_for_text I18n.t('search_results'), :timeout_in_seconds => 5
      assert_contain 'Jeremy Smith'
      assert_match %r{/search/new$}, current_url # url didn't change
    end

  end

end
