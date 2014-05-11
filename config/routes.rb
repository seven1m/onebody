OneBody::Application.routes.draw do

  root to: redirect('/stream')

  resource :account do
    member do
      post :verify_code
      get  :select
      post :select
    end
  end

  resources :people do
    collection do
      get  :schema
      get  :import
      post :import
      post :hashify
      post :batch
      put  :import
    end
    member do
      get  :favs
      get  :testimony
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
    resource :photo
    resources :groups, :pictures, :groupies, :services, :albums, :notes, :verses
    resource :privacy, :blog, :calendar
  end

  resources :families do
    collection do
      get  :schema
      post :hashify
      post :batch
      post :select
    end
    member do
      post :reorder
    end
    resource :photo
    resources :relationships
  end

  resources :groups do
    collection do
      get  :batch
      post :batch
    end
    resources :memberships do
      collection do
        get    :birthdays
        post   :batch
        delete :batch
      end
      resource :privacy
    end
    resources :messages do
      collection do
        post :new
      end
    end
    resources :attendance do
      collection do
        post :batch
      end
    end
    resource :photo
    resources :notes, :prayer_requests, :albums, :attachments
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

  resources :tags, only: :show

  resources :pictures, :prayer_signups, :authentications, :verses, :shares,
            :comments, :prayer_requests, :generated_files

  resources :notes, except: :index

  resource  :setup, :stream, :session, :search, :printable_directory, :privacy

  resources :news, as: :news_items
  get 'news', to: 'news#index'

  resource :style
  get 'style.:browser.css' => 'styles#show', format: 'css', as: :browser_style

  resources :attachments do
    member do
      get :get
    end
  end

  resources :pages, path: 'pages/admin' do
    resources :attachments
  end

  get 'pages/*path' => 'pages#show_for_public', via: :get, as: :page_for_public

  get '/admin' => 'administration/dashboards#show'

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
    resources :syncs do
      member do
        post :create_items
      end
    end
    resources :deleted_people do
      collection do
        put :batch
      end
    end
    resources :updates, :admins, :membership_requests, :reports
    resource :api_key, :logo
  end
end
