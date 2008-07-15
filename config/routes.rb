ActionController::Routing::Routes.draw do |map|
  
  PHOTO_SIZE_METHODS = {:tn => :get, :small => :get, :medium => :get, :large => :get}

  map.connect '', :controller => 'people'
  
  map.resource :account, :member => {:verify_code => :any, :select => :any}
  
  map.resources :people do |people|
    people.resources :groups
    people.resources :pictures
    people.resources :friends, :collection => {:reorder => :post}
    people.resources :remote_accounts, :member => {:sync => :post}
    people.resource :account, :member => {:verify_code => :any, :select => :any}
    people.resource :sync
    people.resource :privacy
    people.resource :blog
    people.resource :wall, :member => {:with => :get}
    people.resource :photo, :member => PHOTO_SIZE_METHODS
  end
  
  map.resources :families do |families|
    families.resource :photo, :member => PHOTO_SIZE_METHODS
  end
  
  map.resources :groups do |groups|
    groups.resources :memberships, :collection => {:batch => :any}
    groups.resources :notes
    groups.resources :messages
    groups.resources :prayer_requests
    groups.resource :photo, :member => PHOTO_SIZE_METHODS
  end
  
  map.resources :albums do |albums|
    albums.resources :pictures, :member => {:next => :get, :prev => :get} do |pictures|
      pictures.resource :photo, :member => PHOTO_SIZE_METHODS
    end
  end
 
  map.resources :recipes do |recipes|
    recipes.resource :photo, :member => PHOTO_SIZE_METHODS
  end

  map.resources :messages do |messages|
    messages.resources :attachments
  end
  
  map.resources :verses
  map.resources :publications
  map.resources :notes
  map.resources :shares
  map.resources :tags
  map.resources :news
  map.resources :comments
  map.resources :helps, :as => 'help'
  
  map.resource :session
  map.resource :search, :member => {:opensearch => :get}
  map.resource :printable_directory
  map.resource :feed
  map.resource :privacy
  
  # almost done...

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
  
  ActionController::Routing::Routes.draw_plugin_routes
end
