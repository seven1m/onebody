OneBody::Application.routes.draw do

  root to: redirect('/stream')

  resource :account do
    member do
      get :verify_code
      post :verify_code
      get  :select
      post :select
    end
  end

  resources :people do
    collection do
      post :batch
    end
    member do
      get :favs
      get :testimony
      get :login
    end
    resources :friends do
      collection do
        post :reorder
      end
    end
    resources :relationships do
      collection do
        post :batch
      end
    end
    resource :account do
      member do
        get  :verify_code
        post :verify_code
        get  :select
        post :select
      end
    end
    resource :stream
    resource :photo
    resources :groups, :pictures, :services, :albums, :verses
    resource :privacy
  end

  resources :families do
    collection do
      post :batch
      post :select
    end
    resource :photo
    resources :relationships
    resources :people do
      member do
        post :update_position
      end
    end
    resource :search
  end

  resources :groups do
    collection do
      get  :batch
      post :batch
    end
    resources :memberships do
      collection do
        post   :batch
        delete :batch
      end
      resource :privacy
    end
    resources :messages do
      collection do
        post :new # XXX why??
      end
    end
    resources :attendance do
      collection do
        post :batch
      end
    end
    resources :tasks do
      member do
        patch :complete
        post :update_position
      end
    end
    resource :stream
    resource :photo
    resources :prayer_requests, :albums
    resource :calendar
  end

  resources :memberships do
    collection do
      get  :batch
      post :batch
    end
  end

  resources :service_categories do
    collection do
      get :batch_edit
      get :close_batch_edit
    end
  end

  resources :albums do
    resources :pictures do
      member do
        get :next
        get :prev
      end
      resource :photo
    end
  end

  resources :messages do
    resources :attachments
  end

  resource :emails

  get 'setup_email' => 'emails#create_route'
  put 'setup_email' => 'emails#create_route'

  resources :tags, only: :show

  resources :pictures, :prayer_signups, :authentications, :shares,
            :comments, :prayer_requests, :generated_files

  resources :verses do
    get 'search', on: :collection
  end

  resource :setup, :session, :search, :printable_directory

  resource :stream do
    resources :people, controller: 'stream_people'
  end

  resources :news, as: :news_items
  get 'news', to: 'news#index'

  resources :attachments do
    member do
      get :get
    end
  end

  resources :pages, path: 'pages/admin' do
    resources :attachments
  end

  resources :documents do
    get :download, on: :member
  end

  resources :tasks do
    member do
      patch :complete
    end
  end

  resources :directory_maps do
    collection do
      get :family_locations
    end
  end

  get 'pages/*path' => 'pages#show_for_public', via: :get, as: :page_for_public

  get '/admin' => 'administration/dashboards#show'
  get '/admin/reports' => 'administration/reports#index'

  namespace :administration, path: :admin do
    resources :emails do
      collection do
        put :batch
      end
    end
    resources :settings do
      collection do
        put :batch
        put :reload
      end
    end
    resources :attendance do
      collection do
        get :prev
        get :next
      end
    end
    resources :deleted_people do
      collection do
        put :batch
      end
    end
    resources :imports do
      patch :execute, on: :member
    end
    resources :updates, :admins, :membership_requests
    namespace :checkin do
      root to: 'dashboards#show'
      resource :dashboard
      resources :groups do
        put :batch, on: :collection
        put :reorder, on: :member
      end
      resources :times do
        resources :groups
      end
      resources :cards, :auths, :labels
    end
    resources :custom_fields
  end

  resource :checkin, controller: 'checkin/checkins'
  namespace :checkin do
    resource :print
    resource :printer
    resources :families, :people, :groups
  end

  namespace :api do
    namespace :v2 do
      jsonapi_resources :people
      jsonapi_resources :families
      jsonapi_resources :groups
      jsonapi_resources :messages
      jsonapi_resources :attachments
      jsonapi_resources :attendance_records
      jsonapi_resources :comments
      jsonapi_resources :verses
      jsonapi_resources :news_items
    end
  end

  post '/pusher/auth_printer'    => 'pusher#auth_printer'
  get '/auth/facebook/callback'  => 'sessions#create_from_external_provider'
  post '/auth/facebook/callback' => 'sessions#create_from_external_provider'
  get '/auth/:provider/setup'    => 'sessions#setup_omniauth'
end
