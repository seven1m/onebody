ActionController::Routing::Routes.draw do |map|
  map.connect '', :controller => "people"
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':controller/:action/:id'
  map.connect ':controller/photo/:id', :action => 'photo', :requirements => { :id => /.*/ }
  
  map.person 'people/view/:id', :controller => 'people', :action => 'view'
  
  map.with_options :controller => 'notes' do |m|
    m.new_note 'notes/edit', :action => 'edit'
    m.edit_note 'notes/edit/:id', :action => 'edit'
    m.delete_note 'notes/delete/:id', :action => 'delete'
  end
end
