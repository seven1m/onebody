ActionController::Routing::Routes.draw do |map|
  
  map.with_options :controller => 'people' do |m|
    m.person 'people/view/:id', :action => 'view'
    m.edit_profile 'people/edit/:id', :action => 'edit'
    m.logged_in 'people', :action => 'index'
    m.browse_directory 'people/browse', :action => 'search', :browse => true
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
  
  map.groups 'groups', :controller => 'groups'

  map.connect '', :controller => "people"
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }

end
