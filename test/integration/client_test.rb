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
      assert_display 'block', '#share'
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

    should 'alert to changes on profile edit when changing tabs' do
      visit "/people/#{people(:tim).id}/edit"
      assert_equal 'false', selenium.js_eval("window.changes")
      selenium.type 'person_first_name', 'John'
      assert_equal 'true', selenium.js_eval("window.changes")
      selenium.click "xpath=//h2[@class='tab']/div[4]"
      assert_equal I18n.t('privacies.you_made_a_change_tab'), selenium.confirmation
      selenium.wait_for_page
      assert_match %r{/people/#{people(:tim).id}/edit#basics$}, current_url
      assert_equal 'John', people(:tim).reload.first_name
      people(:tim).update_attribute(:first_name, 'Tim') # put it back
    end

  end

  context 'Privacy' do

    setup do
      sign_in_as people(:tim)
      visit "/people/#{people(:tim).id}/privacy/edit"
    end

    should 'alert to changes when changing tabs' do
      assert_equal 'false', selenium.js_eval("window.changes")
      selenium.click 'family_share_address_false'
      assert_equal 'true', selenium.js_eval("window.changes")
      selenium.click "xpath=//h2[@class='tab']/div[2]"
      assert_equal I18n.t('privacies.you_made_a_change_tab'), selenium.confirmation
      selenium.wait_for_page
      assert_match %r{/people/#{people(:tim).id}/privacy/edit}, current_url
      assert_equal false, people(:tim).family.reload.share_address?
      people(:tim).family.update_attribute(:share_address, false) # put it back
    end

    should 'hide individual tabs when family visibility is disabled' do
      assert_equal '4', selenium.js_eval("window.$.grep(window.tabs, function(e){ return e.style.display != 'none' }).length")
      selenium.click 'family_visible'
      assert_equal '1', selenium.js_eval("window.$.grep(window.tabs, function(e){ return e.style.display != 'none' }).length")
      selenium.click 'family_visible'
      assert_equal '4', selenium.js_eval("window.$.grep(window.tabs, function(e){ return e.style.display != 'none' }).length")
      selenium.js_eval "window.changes = false" # cancel confirmation popup
    end

  end

  context 'Stream' do

    setup do
      sign_in_as people(:tim)
    end

    should 'show share section when link is clicked' do
      visit '/stream'
      selenium.click "xpath=//p[@id='share-something']/a[1]"
      assert_display 'block', '#share'
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
      assert_display 'block', '#share'
    end

    should 'expand/collapse grouped items' do
      people(:tim).notes.delete_all
      @n1 = people(:tim).forge(:notes)
      sleep 1 # so the creation time will sort properly
      @n2 = people(:tim).forge(:notes)
      @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Note', @n1.id)
      visit '/stream'
      group_id = "#stream-item-group#{@stream_item.id}"
      assert_display 'none', group_id
      selenium.click "xpath=//p[@class='stream-item-group-link']/a[1]"
      assert_display 'block', group_id
      assert_display 'none', '.stream-item-group-link'
    end

  end

  context 'Verses' do

    setup do
      sign_in_as people(:tim)
    end

    should 'hide the new verse form until expanded' do
      visit '/verses'
      assert_display 'none', '#add_verse'
      selenium.click "xpath=//p[@id='add_verse_link']/a[1]"
      assert_display 'block', '#add_verse'
      assert_has_focus '#id'
    end

    should 'show the new verse form if #add in the url' do
      visit '/verses#add'
      assert_display 'block', '#add_verse'
      assert_has_focus '#id'
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

  context 'Groups' do

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

  context 'Pages' do

    setup do
      sign_in_as people(:tim)
    end

    should 'expand/collapse page children' do
      visit '/pages/admin'
      assert_contain 'Foo'
      assert @page = Page.find_by_path('foo')
      selenium.click "page#{@page.id}_expand_link",
        :wait_for           => :condition,
        :javascript         => "window.$('#page#{@page.id}_children *').length > 0",
        :timeout_in_seconds => 5
      selenium.click "page#{@page.id}_collapse_link"
      assert_equal '0', selenium.js_eval("window.$('#page#{@page.id}_children *').length")
    end

  end

  context 'Relationships' do

    setup do
      sign_in_as people(:tim)
    end

    should 'show empty text field when "other" is selected' do
      visit "/people/#{people(:tim).id}/relationships"
      fill_in I18n.t('search.search_by_name'), :with => people(:jeremy).first_name
      selenium.click "xpath=//input[@value='#{I18n.t('relationships.add_relationship_button')}']",
        :wait_for           => :condition,
        :javascript         => "window.$('#results *').length > 0",
        :timeout_in_seconds => 5
      selenium.select "relationship_name", 'value=other'
      assert_display 'inline', '#other_name'
      assert_has_focus '#other_name'
    end

  end

  context 'Message' do

    setup do
      sign_in_as people(:tim)
    end

    should 'preview message' do
      visit "/messages/new?to_person_id=#{people(:jennie).id}"
      assert_has_focus '#message_subject'
      assert_display 'none', '#preview'
      fill_in :message_subject, :with => 'Hi There'
      fill_in :message_body, :with => 'This is a test.'
      selenium.wait_for_condition "window.$('#preview-from').html() != ''", 7
      assert_display 'block', '#preview'
      assert_equal 'From: timmorgan@example.com', selenium.get_text('preview-from')
      assert_equal "#{I18n.t('messages.subject')}: Hi There", selenium.get_text('preview-subject')
      assert_match /^This is a test./, selenium.get_text('preview-email')
    end

  end

  context 'Attendance' do

    setup do
      sign_in_as people(:tim)
    end

    should 'add somebody not in the group' do
      groups(:morgan).attendance_records.delete_all
      visit "/groups/#{groups(:morgan).id}/attendance"
      assert_equal '0', selenium.js_eval("window.$('#attendance_form :checked').length")
      assert_display 'none', '#add_member'
      fill_in :add_person_name, :with => 'Tim'
      selenium.click "xpath=//input[@value='#{I18n.t('search.search_by_name')}']",
        :wait_for           => :condition,
        :javascript         => "window.$('#results *').length > 0",
        :timeout_in_seconds => 5
      selenium.click "xpath=//input[@value='#{I18n.t('search.add_selected')}']",
        :wait_for           => :page
      assert_equal '1', selenium.js_eval("window.$('#attendance_form :checked').length")
    end

  end

  context 'Family' do

    setup do
      sign_in_as people(:tim)
    end

    should 'automatically fill last name as full family name is entered' do
      visit '/families/new'
      # have to simulate onkeyup by calling set_last_name()
      selenium.key_press 'family_name', 'J'; selenium.js_eval("window.set_last_name()")
      assert_equal '', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'o'; selenium.js_eval("window.set_last_name()")
      assert_equal '', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'e'; selenium.js_eval("window.set_last_name()")
      assert_equal '', selenium.field('family_last_name')
      selenium.key_press 'family_name', ' '; selenium.js_eval("window.set_last_name()")
      assert_equal '', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'S'; selenium.js_eval("window.set_last_name()")
      assert_equal 'S', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'm'; selenium.js_eval("window.set_last_name()")
      assert_equal 'Sm', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'i'; selenium.js_eval("window.set_last_name()")
      assert_equal 'Smi', selenium.field('family_last_name')
      selenium.key_press 'family_name', 't'; selenium.js_eval("window.set_last_name()")
      assert_equal 'Smit', selenium.field('family_last_name')
      selenium.key_press 'family_name', 'h'; selenium.js_eval("window.set_last_name()")
      assert_equal 'Smith', selenium.field('family_last_name')
    end

    should 'add existing people to family' do
      visit "/families/#{families(:morgan).id}"
      assert_display 'none', '#add_existing'
      assert_display 'none', '#add_member'
      selenium.click 'add_existing_link'
      assert_display 'block', '#add_existing'
      assert_has_focus '#add_person_name'
    end

  end

end
