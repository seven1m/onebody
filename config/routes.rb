unless defined?(DISABLE_ROUTES)
  ActionController::Routing::Routes.draw do |map|

    PHOTO_SIZE_METHODS = {:tn => :get, :small => :get, :medium => :get, :large => :get}

    map.home '', :controller => 'pages', :action => 'show_for_public'
    
    map.resource :stream
  
    map.resource :account, :member => {:verify_code => :any, :select => :any}
  
    map.resources :people,
      :collection => {:import => :any, :hashify => :post, :schema => :get, :batch => :post, :checkin => :get},
      :member => {:favs => :get, :testimony => :get} do |people|
      people.resources :groups
      people.resources :pictures
      people.resources :friends, :collection => {:reorder => :post}
      people.resources :remote_accounts, :member => {:sync => :post}
      people.resources :groupies
      people.resources :services
      people.resources :albums
      people.resources :feeds
      people.resources :notes
      people.resources :verses
      people.resources :recipes
      people.resource :account, :member => {:verify_code => :any, :select => :any}
      people.resource :sync
      people.resource :privacy
      people.resource :blog
      people.resource :wall, :member => {:with => :get}
      people.resource :photo, :member => PHOTO_SIZE_METHODS
      people.resource :calendar
    end
  
    map.resources :families,
      :collection => {:hashify => :post, :schema => :get, :batch => :post, :select => :post},
      :member => {:reorder => :post} do |families|
      families.resource :photo, :member => PHOTO_SIZE_METHODS
    end
  
    map.resources :groups,
      :collection => {:batch => :any} do |groups|
      groups.resources :memberships, :collection => {:batch => :any}, :has_one => :privacy
      groups.resources :notes
      groups.resources :messages
      groups.resources :prayer_requests
      groups.resources :attendance, :collection => {:batch => :post}
      groups.resources :albums
      groups.resource :photo, :member => PHOTO_SIZE_METHODS
      groups.resource :calendar
    end
    
    map.resources :memberships, :collection => {:batch => :any}
  
    map.resources :service_categories, :collection => {:batch_edit => :get, :close_batch_edit => :get}
  
    map.resources :albums do |albums|
      albums.resources :pictures, :member => {:next => :get, :prev => :get} do |pictures|
        pictures.resource :photo, :member => PHOTO_SIZE_METHODS
      end
    end
    
    map.resources :pictures
 
    map.resources :recipes do |recipes|
      recipes.resource :photo, :member => PHOTO_SIZE_METHODS
    end

    map.resources :messages do |messages|
      messages.resources :attachments
    end
  
    map.resources :feeds
    map.resources :verses
    map.resources :publications
    map.resources :notes
    map.resources :tags
    map.resources :news, :singular => 'news_item'
    map.resources :comments
    map.resources :attachments, :member => {:get => :get}
    map.resources :prayer_requests
    map.resources :external_groups
  
    map.resource :session
    map.resource :search, :member => {:opensearch => :get}
    map.resource :printable_directory
    map.resource :privacy
    map.resource :tour

    map.bible 'bible/:book/:chapter', :controller => 'bibles', :action => 'show',
      :book => 'x', :chapter => 0,
      :requirements => {:book => /[A-Za-z0-9 \+(%20)]+/, :chapter => /\d{1,3}/}
      
    map.resources :pages, :as => 'pages/admin' do |pages|
      pages.resources :attachments
    end
  
    map.with_options :controller => 'pages' do |pages|
      pages.page_for_public 'pages/*path', :action => 'show_for_public', :conditions => {:method => :get}
    end

    map.resource :admin, :controller => 'administration/dashboards'
    map.namespace :administration, :path_prefix => 'admin' do |admin|
      admin.resource :api_key
      admin.resource :logo
      admin.resources :updates
      admin.resources :admins
      admin.resources :membership_requests
      admin.resources :log_items, :collection => {:batch => :put}
      admin.resources :settings, :collection => {:batch => :put, :reload => :put}
      admin.resources :files, :requirements => {:id => /[a-z0-9_]+(\.[a-z0-9_]+)?/}
      admin.resources :attendance
      admin.resource :theme
      admin.namespace :checkin do |checkin|
        checkin.resource :dashboard
        checkin.resources :cards
        checkin.resources :groups, :collection => {:batch => :put, :reorder => :post}
        checkin.resources :times
      end
    end
  
  end
end
