ActionController::Routing::Routes.draw do |map|
  
  map.with_options :controller => 'people' do |m|
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.browse_directory 'people/browse', :action => 'search', :browse => true
    m.person 'people/:id', :action => 'view', :requirements => {:id => /\d/}
    m.logged_in '', :action => 'index'
  end
  
  map.with_options :controller => 'notes' do |m|
    m.new_note 'notes/edit', :action => 'edit'
    m.edit_note 'notes/edit/:id', :action => 'edit'
    m.delete_note 'notes/delete/:id', :action => 'delete'
    m.connect 'notes/:action/:id', :action => 'index'
  end
  
  map.with_options :controller => 'friends' do |m|
    m.remove_friend 'friends/remove/:id', :action => 'remove'
    m.add_friend 'friends/add/:id', :action => 'add'
    m.friends 'friends/view/:id', :action => 'view'
  end
  
  map.shares 'shares', :controller => 'shares'
  
  map.with_options :controller => 'groups' do |m|
    m.groups 'groups', :action => 'index'
    m.group 'groups/view/:id', :action => 'view'
  end
  
  map.with_options :controller => 'notes' do |m|
    m.note 'notes/view/:id', :action => 'view'
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

  map.connect '', :controller => "people"
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }

end
