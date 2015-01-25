# encoding: UTF-8

require "resque/server"

Bountyhill::Application.routes.draw do
  opinio_model

  app = Rack::Builder.new {
    use ::AdminOnlyMiddleware
    run Resque::Server.new
  }.to_app

  mount app, :at => "/jobs"

  # static pages routes
  %w(faq contact imprint terms privacy).each do |static_page|
    match static_page => "static##{static_page}", :via => :get
  end

  # images container routes
  %w(quests offers).each do |images_container|
    match "/#{images_container}/:id/lightbox/:active"  => "#{images_container}#lightbox", :via => :get
  end

  resources :quests do
    opinio
  end
  match "/q/:id"                      => "quests#show",   :via => :get
  match "/quests/category/:category"  => "quests#index",  :via => :get
  match "/quests/:owner_id/list"      => "quests#index",  :via => :get
  
  resources :shares
  
  resources :runs
  match "/runs/:id"         => "runs#update", :via => :post
  match "/runs/:id/start"   => "runs#start",  :via => :get
  match "/runs/:id/cancel"  => "runs#cancel", :via => :get
  
  resources :offers do
    opinio
    member do
      get "activate"
      put "activate"
      get "accept"
      put "accept"
      get "reject"
      put "reject"
      get "withdraw"
      put "withdraw"
    end
  end
  match "/offers/:owner_id/list" => "offers#index",  :via => :get

  resources :users
  match 'profile'           => "users#show",    :via => :get
  match "/users/:id/delete" => "users#delete",  :via => :get

  resources :activities
  
  resources :messages
  
  resources :sessions
  # manual routes for signup, signin, signout
  match "signin"          => "sessions#signin_get",     :via => :get
  match "signin"          => "sessions#signin_post",    :via => :post
  match "signup"          => "sessions#signin_post",    :via => :post
  match "signout"         => "sessions#destroy",        :via => :delete
  match "sessions/cancel" => "sessions#cancel",         :via => :post
  
  resources :identities do 
    member do
      get "delete"
      get "init"
      get "failure"
      post "success"
    end
  end
  # match "identities/failure" => "identities#failure", :via => :post
  # match "identities/delete"  => "identities#delete",  :via => :get

  # omniauth
  match 'auth/:provider/init'     => 'identities#init'
  match 'auth/:provider/callback' => 'identities#success'
  match 'auth/failure'            => 'identities#failure'

  resources :deferred_actions, :only => [:show]
  match 'act'             => 'deferred_actions#show'
  match 'confirm'         => 'deferred_actions#confirm'
  match 'reset_password'  => 'deferred_actions#reset_password'
  
  
  # exeption handling routes
  match '/404' => 'errors#not_found'
  match '/422' => 'errors#unprocessable_entity'
  match '/500' => 'errors#internal_server_error'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
