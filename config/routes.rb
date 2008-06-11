ActionController::Routing::Routes.draw do |map|

  map.resources :blogs
  map.resources :walls
  map.resource :feed
  
  map.with_options :controller => 'setup/dashboard' do |m|
    m.setup 'setup', :action => 'index'
    m.setup_not_authorized 'setup/not_local_or_secret_not_given', :action => 'not_local_or_secret_not_given'
    m.setup_authorize_ip 'setup/authorize_ip', :action => 'authorize_ip'
    m.setup_change_environment 'setup/change_environment', :action => 'change_environment'
    m.setup_environment 'setup/environment', :action => 'environment'
    m.not_local_or_secret_not_given 'setup/not_local_or_secret_not_given', :action => 'not_local_or_secret_not_given'
  end

  map.with_options :controller => 'setup/sites' do |m|
    m.setup_sites 'setup/sites', :action => 'index'
    m.setup_edit_multisite 'setup/sites/edit_multisite', :action => 'edit_multisite'
    m.setup_edit_site 'setup/sites/edit', :action => 'edit'
    m.setup_delete_site 'setup/sites/delete', :action => 'delete'
  end

  map.with_options :controller => 'setup/database' do |m|
    m.setup_database 'setup/database', :action => 'index'
    m.setup_load_fixtures 'setup/database/load_fixtures', :action => 'load_fixtures'
    m.setup_migrate_database 'setup/database/migrate', :action => 'migrate'
    m.setup_edit_database 'setup/database/edit', :action => 'edit'
    m.setup_backup_database 'setup/database/backup', :action => 'backup'
  end

  map.with_options :controller => 'setup/settings' do |m|
    m.setup_edit_settings 'setup/settings/edit/:id', :action => 'edit'
    m.setup_global_settings 'setup/settings/global', :action => 'global'
    m.setup_settings 'setup/settings/:id', :action => 'view'
  end
  
  map.with_options :controller => 'people', :protocol => 'http' do |m|
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.edit_person 'people/edit/:id', :action => 'edit'
    m.person_privacy 'people/privacy/:id', :action => 'privacy'
    m.person_email_prefs 'people/email/:id', :action => 'email'
    m.person_photo 'people/photo/:id', :action => 'photo'
    m.person_groups 'people/groups/:id', :action => 'groups'
    m.new_person 'people/edit', :action => 'edit'
    m.delete_person 'people/delete/:id', :action => 'delete'
    m.person 'people/view/:id', :action => 'view'#, :requirements => {:id => /\d/}
    m.recently 'people/recently', :action => 'recently'
    m.logged_in '', :action => 'index'
    m.services_from 'people/services/:id', :action => 'services'
    m.opensearch 'opensearch.xml', :action => 'opensearch', :format => 'xml'
    m.remove_verse_from_person 'people/remove_verse/:id', :action => 'remove_verse'
    m.freeze_account 'people/freeze/:id', :action => 'edit'
    m.person_add_verse 'people/add_verse', :action => 'add_verse'
    m.person_remove_verse 'people/remove_verse', :action => 'remove_verse'
  end
  
  map.with_options :controller => 'families' do |m|
    m.family 'families/view/:id', :action => 'view'
    m.new_family 'families/edit', :action => 'edit'
    m.edit_family 'families/edit/:id', :action => 'edit'
  end
  
  map.with_options :controller => 'directory' do |m|
    m.search_directory 'directory', :action => 'index'
    m.select_person 'directory/search/select', :action => 'search', :select_person => true
    m.browse_directory 'directory/browse', :action => 'search', :browse => true
    m.search_friends 'directory/search_friends', :action => 'search', :search_friends => true
    m.service_directory 'directory/service', :action => 'search', :service => true
    m.select_for_nametags 'directory/select_for_nametags', :action => 'select_for_nametags'
    m.done_selecting_for_nametags 'directory/done_selecting_for_nametags', :action => 'done_selecting_for_nametags'
    m.directory_pickup_pdf 'directory/directory_pickup_pdf', :action => 'directory_pickup_pdf'
  end
  
  map.with_options :controller => 'notes' do |m|
    m.new_note 'notes/edit', :action => 'edit'
    m.edit_note 'notes/edit/:id', :action => 'edit'
    m.delete_note 'notes/delete/:id', :action => 'delete'
    m.note 'notes/view/:id', :action => 'view'
    m.connect 'notes/:action/:id', :action => 'index'
  end
  
  map.with_options :controller => 'prayer_requests' do |m|
    m.new_prayer_request 'prayer_requests/edit', :action => 'edit'
    m.edit_prayer_request 'prayer_requests/edit/:id', :action => 'edit'
    m.delete_prayer_request 'prayer_requests/delete/:id', :action => 'delete'
    m.prayer_request 'prayer_requests/view/:id', :action => 'view'
    m.connect 'prayer_requests/:action/:id', :action => 'index'
    m.answered_prayer_requests 'prayer_requests/answered/:id', :action => 'answered'
  end
  
  map.with_options :controller => 'prayer' do |m|
    m.prayer_event 'prayer/event', :action => 'event'
  end
    
  map.with_options :controller => 'friends' do |m|
    m.remove_friend 'friends/remove/:id', :action => 'remove'
    m.add_friend 'friends/add/:id', :action => 'add'
    m.friends 'friends/view/:id', :action => 'view'
    m.friend_turned_down 'friends/turned_down', :action => 'turned_down'
  end
  
  map.shares 'shares', :controller => 'shares'
  map.publications 'publications', :controller => 'publications'
  
  map.with_options :controller => 'groups' do |m|
    m.groups 'groups', :action => 'index'
    m.group 'groups/view/:id', :action => 'view'
    m.new_group 'groups/edit', :action => 'edit'
    m.edit_group 'groups/edit/:id', :action => 'edit'
    m.approve_group 'groups/approve/:id', :action => 'approve'
    m.group_membership_requests 'groups/membership_requests/:id', :action => 'membership_requests'
    m.toggle_email 'groups/toggle_email/:id', :action => 'toggle_email'
    m.search_groups 'groups/search', :action => 'search'
    m.join_group 'groups/join/:id', :action => 'join'
    m.leave_group 'groups/leave/:id', :action => 'leave'
  end
  
  map.with_options :controller => 'verses' do |m|
    m.verses 'verses', :action => 'index'
    m.verse 'verses/view/:id', :action => 'view'
    m.verse_add_tags 'verses/add_tags/:id', :action => 'add_tags'
    m.delete_tag_from_verse 'verses/delete_tag/:id', :action => 'delete_tag'
  end
  
  map.with_options :controller => 'recipes' do |m|
    m.recipe 'recipes/view/:id', :action => 'view'
    m.new_recipe 'recipes/edit', :action => 'edit'
    m.edit_recipe 'recipes/edit/:id', :action => 'edit'
    m.search_recipes 'recipes/search', :action => 'search'
    m.delete_recipe 'recipes/delete/:id', :action => 'delete'
    m.recipe_add_tags 'recipes/add_tags/:id', :action => 'add_tags'
    m.delete_tag_from_recipe 'recipe/delete_tag/:id', :action => 'delete_tag'
  end
  
  map.with_options :controller => 'music' do |m|
    m.music 'music', :action => 'index'
    m.song 'music/view/:id', :action => 'view'
    m.edit_song 'music/edit/:id', :action => 'edit'
    m.delete_tag_from_music 'music/delete_tag/:id', :action => 'delete_tag'
  end
  
  map.with_options :controller => 'comments' do |m|
    m.delete_comment 'comments/delete/:id', :action => 'delete'
  end
  
  map.with_options :controller => 'events' do |m|
    m.events 'events', :action => 'index'
    m.event 'events/view/:id', :action => 'view'
    m.remove_verse_from_event 'events/remove_verse/:id', :action => 'remove_verse'
  end
  
  map.with_options :controller => 'administration/dashboard' do |m|
    m.admin 'administration/dashboard', :action => 'index'
    m.admin_log 'administration/dashboard/log', :action => 'log'
    m.admin_updates 'administration/dashboard/updates', :action => 'updates'
    m.remove_admin 'administration/dashboard/remove_admin', :action => 'remove_admin'
    m.edit_attribute 'administration/dashboard/edit_attribute', :action => 'edit_attribute'
    m.add_admin 'administration/dashboard/add_admin', :action => 'add_admin'
    m.admin_membership_requests 'administration/dashboard/admin_membership_requests', :action => 'admin_membership_requests'
    m.mark_reviewed 'administration/dashboard/mark_reviewed', :action => 'mark_reviewed'
    m.admin_toggle_complete 'administration/dashboard/toggle_complete', :action => 'toggle_complete'
    m.admin_delete_update 'administration/dashboard/delete_update', :action => 'delete_update'
  end

  map.with_options :controller => 'administration/settings' do |m|
    m.settings 'administration/settings', :action => 'index'
    m.edit_settings 'administration/settings/edit/:id', :action => 'edit'
  end

  map.with_options :controller => 'checkin/admin' do |m|
    # FIXME: cannot get next route to work minus "index" on the end - clashes with checkin_section route
    m.checkin_admin 'checkin/admin/index', :action => 'index'
    m.checkin_report 'checkin/admin/report', :action => 'report'
  end
  
  map.with_options :controller => 'checkin' do |m|
    m.checkin 'checkin', :action => 'index'
    m.checkin_date_and_time 'checkin/date_and_time', :action => 'date_and_time'
    m.report_date_and_time 'checkin/report_date_and_time', :action => 'report_date_and_time'
    m.checkin_section 'checkin/:section', :action => 'section'
    m.check 'checkin/:section/check', :action => 'check'
    m.checkin_attendance 'checkin/:section/attendance', :action => 'attendance'
    m.void_attendance_record 'checkin/:section/void', :action => 'void'
  end
  
  map.with_options :controller => 'nametags' do |m|
    m.nametags 'nametags', :action => 'index'
    m.add_nametag 'nametags/add/:id', :action => 'add'
    m.remove_nametag 'nametags/remove/:id', :action => 'remove'
    m.barcode 'nametags/barcode/:id', :action => 'barcode'
    m.print_nametags 'nametags/print', :action => 'print'
  end
  
  map.with_options :controller => 'remote_accounts' do |m|
    m.new_remote_account 'remote_accounts/edit', :action => 'edit'
    m.edit_remote_account 'remote_accounts/edit/:id', :action => 'edit'
    m.delete_remote_account 'remote_accounts/delete/:id', :action => 'delete'
    m.sync_remote_account 'remote_accounts/sync/:id', :action => 'sync'
    m.remote_accounts 'remote_accounts/:person_id', :action => 'index'
    m.sync_person_options 'remote_accounts/sync_person_options/:id', :action => 'sync_person_options'
    m.sync_person 'remote_accounts/sync_person/:id', :action => 'sync_person'
  end
  
  map.with_options :controller => 'account' do |m|
    m.edit_account 'account/edit/:id', :action => 'edit'
    m.sign_in 'account/sign_in', :action => 'sign_in'
    m.sign_out 'account/sign_out', :action => 'sign_out'
    m.verify_email 'account/verify_email', :action => 'verify_email'
    m.verify_code 'account/verify_code', :action => 'verify_code'
    m.select_person 'account/select_person', :action => 'select_person'
    m.safeguarding_children 'account/safeguarding_children', :action => 'safeguarding_children'
    m.change_email_and_password 'account/change_email_and_password', :action => 'change_email_and_password'
  end
  
  map.with_options :controller => 'help' do |m|
    m.help 'help', :action => 'index'
    m.privacy_policy 'help/privacy_policy', :action => 'privacy_policy'
    m.unauthorized 'help/unauthorized', :action => 'unauthorized'
    m.bad_status 'help/bad_status', :action => 'bad_status'
  end
  
  map.with_options :controller => 'tags' do |m|
    m.tag 'tags/view/:id', :action => 'view'
  end

  map.with_options :controller => 'news' do |m|
    m.new_item 'news/view/:id', :action => 'view'
  end
  
    
  #map.with_options :controller => 'messages' do |m|
  #  m.message 'messages/view/:id', :action => 'view'
  #  m.send_email 'messages/send_email/:id', :action => 'send_email'
  #end
  map.resources :messages
  
  map.with_options :controller => 'pictures' do |m|
    m.picture 'pictures/view/:id', :action => 'view', :requirements => { :id => /.*/ }
    m.picture_photo 'pictures/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }
  end
  
  #map.connect ':controller/service.wsdl', :action => 'wsdl'
  #map.connect ':controller/:action/:id'
  map.photo ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }
end
