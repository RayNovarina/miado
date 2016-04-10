Rails.application.routes.draw do
  get 'messages/index'

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

  resources :users, only: [:index, :show]
  get '/settings', to: 'users#settings', as: 'settings'

=begin
  api/slack/slash/commands --> Api::BaseController::Commands
  /users/teams/members/channels/tasks/index,show,new,edit,destroy
  1) command:
    /do rev 1 spec @susan /jun15
    { "token"=>"tY1fGlQ1V2f6bskupMJa6ryY",
      "team_id"=>"T0VN565N0",
      "team_domain"=>"shadowhtracteam",
      "channel_id"=>"C0VNKV7BK",
      "channel_name"=>"general",
      "user_id"=>"U0VNMUXNZ",
      "user_name"=>"dawnnova",
      "command"=>"/do",
      "text"=>"help",
      "response_url"=>"https://hooks.slack.com/commands/T0VN565N0/31996879410/vAludpuTljkWnSvOliaSgWvz",
      "controller"=>"api/slack/slash/commands",
      "action"=>"create"
    }
  2) becomes route:
    channel_tasks POST /channels/:channel_id/tasks(.:format)  to: tasks#create
  3) response:
    :thumbs_up: Task 4 created and assigned to @susan. Due date is Tues. June 15. Type /do list for complete list.
    :bulb: You can unassign someone from the task by running /do unassign @susan 4
=end

  # For api. api/slack/slash for Slack slash commands.
  namespace :api do
    # resources :users, only: [:index, :show, :create, :update]
    # resources :topics, except: [:edit, :new]
    namespace :slack do
      namespace :slash do
        resources :commands, only: [:create]
      end
    end
  end

  # -------------------------------
  # App:
  # Landing page, About
  root 'pages#welcome'
  get  'about', to: 'pages#about'
  get '/add_to_slack', to: 'pages#add_to_slack', as: 'add_to_slack'
  get '/welcome/new', to: 'pages#welcome_new', as: 'welcome_new'
  get '/welcome/add_to_slack_new', to: 'pages#welcome_add_to_slack_new', as: 'welcome_add_to_slack_new'
  get '/welcome/back', to: 'pages#welcome_back', as: 'welcome_back'
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
