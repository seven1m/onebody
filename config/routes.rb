ActionController::Routing::Routes.draw do |map|
  
  map.with_options :controller => 'people' do |m|
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.browse_directory 'people/browse', :action => 'search', :browse => true
    m.logged_in 'people', :action => 'index'
    m.person 'people/:id', :action => 'view'
  end
  
  map.with_options :controller => 'notes' do |m|
    m.new_note 'notes/edit', :action => 'edit'
    m.edit_note 'notes/edit/:id', :action => 'edit'
    m.delete_note 'notes/delete/:id', :action => 'delete'
  end
  
  map.with_options :controller => 'friends' do |m|
    m.remove_friend 'friends/remove/:id', :action => 'remove'
    m.add_friend 'friends/add/:id', :action => 'add'
    m.friends 'friends/:id', :action => 'view'
  end
  
  map.shares 'shares', :controller => 'shares'
  
  map.with_options :controller => 'groups' do |m|
    m.groups 'groups', :action => 'index'
    m.group 'groups/:id', :action => 'view'
  end
  
  map.with_options :controller => 'notes' do |m|
    m.note 'notes/:id', :action => 'view'
  end
  
  map.with_options :controller => 'verses' do |m|
    m.verse 'verses/:id', :action => 'view'
  end
  
  map.with_options :controller => 'recipes' do |m|
    m.recipe 'recipes/:id', :action => 'view'
  end
  
  map.with_options :controller => 'events' do |m|
    m.event 'events/:id', :action => 'view'
  end

  map.connect '', :controller => "people"
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }

end
