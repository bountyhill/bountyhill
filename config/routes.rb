require "resque/server"

Bountyhill::Application.routes.draw do
  opinio_model

  app = Rack::Builder.new {
    use ::AdminOnlyMiddleware
    run Resque::Server.new
  }.to_app

  mount app, :at => "/jobs"

  # just temporary...
  %w(quests offers).each do |mock|
    match "mocks/#{mock}/:page" => "mocks##{mock}"
  end

  %w(help about privacy terms contact).each do |static_page|
    match static_page => "static##{static_page}"    
  end

  resources :quests do
    opinio
  end
  
  resources :shares
  match "/shares/:id" => "shares#update", :via => :post

  match "/q/:id" => "quests#show", :via => :get
  
  resources :runs
  match "/runs/:id" => "runs#update", :via => :post
  match "/runs/:id/start" => "runs#start", :via => :get
  
  resources :offers do
    opinio

    member do
      post "accept"
      post "decline"
      post "withdraw"
    end
  end
  resources :users

  match 'profile(/:tab)' => "users#show"

  # manual routes for signup, signin, signout, twitter signin
  match "signin" => "sessions#signin_get",      :via => :get
  match "signin" => "sessions#signin_post",     :via => :post
  match "signout" => "sessions#signout_delete", :via => :delete
  match "sessions/cancel" => "sessions#cancel", :via => :post

  match "sessions/twitter" => "sessions#twitter_post", :via => :post
  match "sessions/twitter" => "sessions#twitter", :via => :get
  
  # 

  resources :deferred_actions, :only => [:show]
  match 'act'  => 'deferred_actions#show'
  match 'confirm' => 'deferred_actions#confirm'
  match 'reset_password' => 'deferred_actions#reset_password'
  
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
  root :to => 'static#home'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
