require "#{File.dirname(__FILE__)}/../test_helper"

class ClientTest < ActionController::IntegrationTest

  include WebratTestHelper
  self.use_transactional_fixtures = false

  context 'Profile' do

    setup do
      sign_in_as people(:tim)
      visit "/people/#{people(:tim).id}"
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

  context 'Stream' do

    setup do
      sign_in_as people(:tim)
    end

    should 'show share section when link is clicked' do
      visit '/stream'
      selenium.click "xpath=//p[@id='share-something']/a[1]"
      assert_equal '', selenium.js_eval("window.document.getElementById('share').style.display")
    end

    should 'load albums on picture tab' do
      visit '/stream'
      selenium.js_eval("window.$('#share').show()")
      selenium.click "xpath=//div[@id='share']/h2[@class='tab']/div[2]",
        :wait_for           => :condition,
        :javascript         => 'window.albums != null',
        :timeout_in_seconds => 5
      assert_equal 1, selenium.js_eval("window.albums.length").to_i
      assert_equal 2, selenium.js_eval("window.$('#album_id *').length").to_i
    end

    should 'auto-show share block if hash in url' do
      visit '/groups' # have to fake out selenium for the next step...
      visit '/stream#picture'
      assert_equal '', selenium.js_eval("window.document.getElementById('share').style.display")
    end

    should 'expand/collapse grouped items' do
      people(:tim).notes.delete_all
      @n1 = people(:tim).forge(:notes)
      sleep 1 # so the creation time will sort properly
      @n2 = people(:tim).forge(:notes)
      @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Note', @n1.id)
      visit '/stream'
      group_id = "#stream-item-group#{@stream_item.id}"
      assert_equal 'none', selenium.js_eval("window.$('#{group_id}').css('display')")
      selenium.click "xpath=//p[@class='stream-item-group-link']/a[1]"
      assert_equal 'block', selenium.js_eval("window.$('#{group_id}').css('display')")
      assert_equal 'none', selenium.js_eval("window.$('.stream-item-group-link').css('display')")
    end

  end

  context 'Verse' do

    setup do
      sign_in_as people(:tim)
    end

    should 'hide the new verse form until expanded' do
      visit '/verses'
      assert_equal 'none', selenium.js_eval("window.$('#add_verse').css('display')")
      selenium.click "xpath=//p[@id='add_verse_link']/a[1]"
      assert_equal 'block', selenium.js_eval("window.$('#add_verse').css('display')")
      assert_equal 'id', selenium.js_eval("window.$('*:focus')[0].id")
    end

    should 'show the new verse form if #add in the url' do
      visit '/verses#add'
      assert_equal 'block', selenium.js_eval("window.$('#add_verse').css('display')")
      assert_equal 'id', selenium.js_eval("window.$('*:focus')[0].id")
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

  context 'Group' do

    setup do
      sign_in_as people(:tim)
    end

    should 'batch edit all groups' do
      visit '/groups/batch'
      selenium.click "groups_#{groups(:morgan).id}_private"
      fill_in "groups_#{groups(:morgan).id}_name", :with => 'foobar'
      assert_equal 'true', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_name').hasClass('changed')")
      assert_equal 'true', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_private').hasClass('changed')")
      assert_equal 'false', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_private').next().hasClass('changed')")
      assert_equal 'false', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_hidden').hasClass('changed')")
      selenium.click "name=commit",
        :wait_for           => :condition,
        :javascript         => "window.$('#loading').css('display') == 'none'",
        :timeout_in_seconds => 10
      assert_equal I18n.t('changes_saved'), selenium.alert
      assert_equal 'foobar', groups(:morgan).reload.name
      assert groups(:morgan).private?
      # put it back
      selenium.click "groups_#{groups(:morgan).id}_private"
      fill_in "groups_#{groups(:morgan).id}_name", :with => 'Morgan Group'
      assert_equal 'true', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_name').hasClass('changed')")
      assert_equal 'false', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_private').hasClass('changed')")
      assert_equal 'true', selenium.js_eval("window.$('#groups_#{groups(:morgan).id}_private').next().hasClass('changed')")
      selenium.click "name=commit",
        :wait_for           => :condition,
        :javascript         => "window.$('#loading').css('display') == 'none'",
        :timeout_in_seconds => 10
      assert_equal I18n.t('changes_saved'), selenium.alert
      assert_equal 'Morgan Group', groups(:morgan).reload.name
      assert !groups(:morgan).private?
    end

  end

end
