Rails.application.routes.draw do
  # resources :omniauth_providers, only: [:index, :show, :destroy]
  resources :installations, only: [:index, :show, :destroy]
  #
  # per: https://github.com/plataformatec/devise#getting-started
  #   "you can customize each controller", "Tell the router to use this
  #   controller"
  # and for oauth per:
  #   https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations',
               omniauth_callbacks: 'users/omniauth_callbacks'
             }
  get '/auth/slack/setup', to: 'sessions#setup', as: 'oauth_setup'

  resources :users, only: [:index, :show, :destroy]

  # get '/installations', to: 'channels#installations_index', as: 'installations'

  resources :teams, only: [:index, :show, :destroy] do
    resources :members, only: [:index]
    resources :channels, only: [:index]
    resources :items, only: [:index]
  end

  resources :members, only: [:index, :show, :destroy]

  resources :channels, only: [:index, :show, :destroy] do
    resources :items, only: [:index]
  end

  resources :items, only: [:index]

  get '/settings', to: 'users#settings', as: 'settings'

  # For api. api/slack/slash for Slack slash commands.
  namespace :api do
    # resources :users, only: [:index, :show, :create, :update]
    # resources :topics, except: [:edit, :new]
    namespace :slack do
      namespace :slash do
        resources :commands, only: [:create]
        resources :deferred, only: [:create]
      end
    end
  end

  resources :comments, only: [:create]

  get 'messages/index', to: 'messages#index'

  # -------------------------------
  # App:
  # Landing page, About
  # root 'pages#welcome'
  root 'pages#add_to_slack'
  get '/about', to: 'pages#about'
  get '/add_to_slack', to: 'pages#add_to_slack', as: 'add_to_slack'
  get '/welcome', to: 'pages#welcome', as: 'welcome'
  get '/welcome/new', to: 'pages#welcome_new', as: 'welcome_new'
  get '/welcome/add_to_slack_new', to: 'pages#welcome_add_to_slack_new', as: 'welcome_add_to_slack_new'
  get '/welcome/back', to: 'pages#welcome_back', as: 'welcome_back'
  get '/tutorials', to: 'pages#tutorials'
  # -------------------------------

  # The priority is based upon order of creation:
  # first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically)
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
