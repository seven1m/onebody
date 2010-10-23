require "#{File.dirname(__FILE__)}/../test_helper"

class ClientTest < ActionController::IntegrationTest

  include WebratTestHelper
  self.use_transactional_fixtures = false

  context 'Profile' do

    setup do
      sign_in_as people(:tim)
      visit "/people/#{people(:tim).id}"
      selenium.wait_for_page(5)
    end

    should 'show share section' do
      assert_equal '', selenium.js_eval("window.document.getElementById('share').style.display")
    end

    should 'load albums on picture tab' do
      people(:tim).albums.delete_all
      @album = people(:tim).forge(:album)
      selenium.click "xpath=//div[@id='share']/h2[@class='tab']/div[2]",
        :wait_for           => :condition,
        :javascript         => 'window.albums != null',
        :timeout_in_seconds => 5
      assert_equal 1, selenium.js_eval("window.albums.length").to_i
      assert_equal 2, selenium.js_eval("window.$('#album_id *').length").to_i
    end

  end

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
