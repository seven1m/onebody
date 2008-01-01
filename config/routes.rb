ActionController::Routing::Routes.draw do |map|
  
  map.with_options :controller => 'people' do |m|
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.edit_person 'people/edit/:id', :action => 'edit'
    m.new_person 'people/edit', :action => 'edit'
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
  
  map.with_options :controller => 'settings' do |m|
    m.settings 'admin/settings', :action => 'index'
  end

  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }
end
