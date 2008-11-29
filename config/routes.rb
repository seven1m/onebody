ActionController::Routing::Routes.draw do |map|
  
  PHOTO_SIZE_METHODS = {:tn => :get, :small => :get, :medium => :get, :large => :get}

  map.home '', :controller => 'pages', :action => 'show_for_public'
  
  map.resource :account, :member => {:verify_code => :any, :select => :any}
  
  map.resources :people,
    :collection => {:import => :any, :hashify => :get, :schema => :get, :batch => :post} do |people|
    people.resources :groups
    people.resources :pictures
    people.resources :friends, :collection => {:reorder => :post}
    people.resources :remote_accounts, :member => {:sync => :post}
    people.resources :groupies
    people.resource :account, :member => {:verify_code => :any, :select => :any}
    people.resource :sync
    people.resource :privacy
    people.resource :blog
    people.resource :wall, :member => {:with => :get}
    people.resource :photo, :member => PHOTO_SIZE_METHODS
    people.resources :services
  end
  
  map.resources :families,
    :collection => {:hashify => :get, :schema => :get, :batch => :post, :select => :post},
    :member => {:reorder => :post} do |families|
    families.resource :photo, :member => PHOTO_SIZE_METHODS
  end
  
  map.resources :groups do |groups|
    groups.resources :memberships, :collection => {:batch => :any}, :has_one => :privacy
    groups.resources :notes
    groups.resources :messages
    groups.resources :prayer_requests
    groups.resources :attendance, :collection => {:batch => :post}
    groups.resources :albums
    groups.resource :photo, :member => PHOTO_SIZE_METHODS
  end
  
  map.resources :service_categories, :collection => {:batch_edit => :get, :close_batch_edit => :get}
  
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
  map.resources :attachments, :member => {:get => :get}
  
  map.resource :session
  map.resource :search, :member => {:opensearch => :get}
  map.resource :printable_directory
  map.resource :feed
  map.resource :privacy
  
  map.resources :pages, :as => 'pages/admin' do |pages|
    pages.resources :attachments
  end
  
  map.with_options :controller => 'pages' do |pages|
    pages.page_for_public 'pages/*path', :action => 'show_for_public', :conditions => {:method => :get}
  end

  map.admin 'admin', :controller => 'administration/dashboards'
  map.namespace :administration, :path_prefix => 'admin' do |admin|
    admin.resource :api_key
    admin.resource :logo
    admin.resources :updates
    admin.resources :admins
    admin.resources :membership_requests
    admin.resources :log_items, :collection => {:batch => :put}
    admin.resources :settings, :collection => {:batch => :put}
    admin.resources :scheduled_tasks
  end
  
  ActionController::Routing::Routes.draw_plugin_routes rescue nil
  
end
