ActionController::Routing::Routes.draw do |map|
  
  map.with_options :controller => 'setup/dashboard' do |m|
    m.setup 'setup', :action => 'index'
    m.setup_not_authorized 'setup/not_local_or_secret_not_given', :action => 'not_local_or_secret_not_given'
    m.setup_authorize_ip 'setup/authorize_ip', :action => 'authorize_ip'
    m.setup_change_environment 'setup/change_environment', :action => 'change_environment'
    m.setup_environment 'setup/environment', :action => 'environment'
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
  
  map.with_options :controller => 'people' do |m|
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.edit_person 'people/edit/:id', :action => 'edit'
    m.new_person 'people/edit', :action => 'edit'
    m.delete_person 'people/delete/:id', :action => 'delete'
    m.person 'people/view/:id', :action => 'view'#, :requirements => {:id => /\d/}
    m.recently 'people/recently', :action => 'recently'
    m.logged_in '', :action => 'index'
    m.services_from 'people/services/:id', :action => 'services'
    m.opensearch 'opensearch.xml', :action => 'opensearch', :format => 'xml'
  end
  
  map.with_options :controller => 'families' do |m|
    m.family 'families/view/:id', :action => 'view'
    m.new_family 'families/edit', :action => 'edit'
    m.edit_family 'families/edit/:id', :action => 'edit'
  end
  
  map.with_options :controller => 'directory' do |m|
    m.search_directory 'directory', :action => 'index'
    m.select_person 'directory/search', :action => 'search', :select_person => true
    m.browse_directory 'directory/browse', :action => 'search', :browse => true
    m.search_friends 'directory/search_friends', :action => 'search', :search_friends => true
    m.service_directory 'directory/service', :action => 'search', :service => true
    m.select_for_nametags 'directory/select_for_nametags', :action => 'select_for_nametags'
    m.done_selecting_for_nametags 'directory/done_selecting_for_nametags', :action => 'done_selecting_for_nametags'
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
  end
  
  map.with_options :controller => 'friends' do |m|
    m.remove_friend 'friends/remove/:id', :action => 'remove'
    m.add_friend 'friends/add/:id', :action => 'add'
    m.friends 'friends/view/:id', :action => 'view'
  end
  
  map.shares 'shares', :controller => 'shares'
  map.publications 'publications', :controller => 'publications'
  
  map.with_options :controller => 'groups' do |m|
    m.groups 'groups', :action => 'index'
    m.group 'groups/view/:id', :action => 'view'
    m.group_membership_requests 'groups/membership_requests/:id', :action => 'membership_requests'
  end
  
  map.with_options :controller => 'messages' do |m|
    m.message 'messages/view/:id', :action => 'view'
    m.send_email 'messages/send_email/:id', :action => 'send_email'
  end
  
  map.with_options :controller => 'verses' do |m|
    m.verse 'verses/view/:id', :action => 'view'
  end
  
  map.with_options :controller => 'recipes' do |m|
    m.recipe 'recipes/view/:id', :action => 'view'
  end
  
  map.with_options :controller => 'events' do |m|
    m.event 'events/view/:id', :action => 'view'
  end
  
  map.with_options :controller => 'administration/dashboard' do |m|
    m.admin 'administration/dashboard', :action => 'index'
  end

  map.with_options :controller => 'administration/settings' do |m|
    m.settings 'administration/settings', :action => 'index'
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

  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }
end
