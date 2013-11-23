Rails.application.routes.draw do

  resources :conferences

  resources :messages

  match "/manifest" => "dashboard#cache_manifest"
  
  resources :authors do
    member do
      post :replace
    end
  end

  resources :submissions

  resources :registrants do
    member do
      put :toggle_activation_whitelist
    end
    collection do
      put :whitelist
    end
  end
  
  resources :umin_rows

  resources :meet_up_comments

  resources :participations

  resources :meet_ups do
    member do
      put 'participate'
    end
  end

  resources :global_messages
  
  resources :receipts do
    collection do
      put 'mark_read_by_sender'
      put 'mark_read'
      put 'mark_unread'
    end
  end

  resources :likes do
    collection do 
      get 'by_day'
      post 'batch_request_likes'
      post 'vote'
      get 'my_votes'
      get 'likes_report'
      get 'votes_report'
    end
    member do
      get 'my'
      get 'my_schedule'
      put 'schedulize'
      put 'unschedulize'
    end
  end


  get "user_sessions/new"

  get "browser(/:session_id)" => "browser#list", :as => :list_browser

  get "browser/details/:presentation_id" => "browser#details"
  
  get "login" => "user_sessions#new", :as => :login
  get "logout" => "user_sessions#destroy", :as => :logout

  get "schedule" => "schedule#index"

  resources :pages

  resources :authorships do
    collection do
      post 'sort'
      post 'drop_on_submission'
    end
  end

  resources :comments do
    member do
      get 'reply'
    end
  end

  resources :presentation_groups

  resources :rooms do
    member do
      put 'move_up'
      put 'move_down'
    end
  end
  
  resources :poster_sessions do
    member do
      get 'like_highlights'
      get 'list'
      get 'list_highlights'
      get 'show_test'
    end
    collection do
      get 'container'
    end
  end

  resources :booth_sessions do
    member do
      get 'like_highlights'
      get 'list'
      get 'list_highlights'
      get 'show_test'
    end    
  end
  
  resources :timetable do
    member do
      get 'like_highlights'
      get 'list'
    end
    collection do
      get 'container'
    end
  end
  
  resources :dashboard do
    collection do
      get 'liked_presentations_ajax'
      get 'my_presentations_ajax'
      get 'scheduled_presentations_ajax'
      get 'private_messages_ajax'
      get 'meet_ups_ajax'
      get 'global_messages_ajax'
      get 'notifications'
      get 'global_messages'
      get 'my_presentations'
      get 'my_meet_ups'
      get 'private_messages'
      get 'social_links'
      post 'batch_request_pages'
    end
  end
  
  resources :sessions do
    member do
      get 'detail'
      get 'poster_row'
      get 'social_box'
      get 'poster_social_box'
      get 'download_pdf'
      get 'download_full_day_pdf'
      put 'order_presentations_by_number'
      put 'set_presentation_duration'
      get 'query'
    end
    collection do
      post 'batch_request_liked_sessions'
      get 'download_full_pdf'
    end
  end

  resources :presentations do
    member do
      get 'next'
      get 'previous'
      get 'likes'
      get 'comments'
      get 'social_box'
      put 'toggle_schedule'
      post 'create_comment'
      get 'related'
      get 'heading'
      put 'change_ad_category'
    end
    collection do
      get 'my'
      post 'sort'
      post 'batch_request_likes'
    end
  end

  resources :users do
    member do
      put 'set_global_message_to_read'
      put 'reset_read_global_messages'
      get 'settings', :to => 'users#settings'
      put 'settings', :to => 'users#update_settings'
      get 'edit_name'
      put 'update_name'
      get 'admin_panel'
    end
    collection do
      get 'admin_search'
      get 'admin_search_by_registration_id'
    end
  end
  
  resources :user_sessions do
    collection do
      post 'switch'
    end
  end
  
  resources :private_messages do
    collection do
      get 'threads'
    end
  end

  match 'private_messages/conversation/:with' => 'private_messages#conversation', :as => 'conversation_private_messages'

  resources :search

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Kamishibai testing and documentation pages
  match 'docs/batch' => 'docs#batch', :as => "docs_batch"
  match 'docs/test_batch' => 'docs#test_batch', :as => "docs_test_batch"
  match 'docs(/:folder)/manifest' => 'docs#manifest', :as => "docs_manifest"
  match 'docs/:page(/:sub_page)' => 'docs#show', :as => "docs", :via => [:get]
  match 'docs/:page(/:sub_page)' => 'docs#create', :as => "docs", :via => [:post]
  match 'docs(/)' => 'docs#index', :as => "docs_root"

  match 'tests/:page(/:sub_page)' => 'tests#show', :as => "tests", :via => [:get]

  # Admin pages that are not bound to any resource
  match 'admin/:action' => 'admin', :as => "admin"

  # Simple static pages from http://blog.hasmanythrough.com/2008/4/2/simple-pages
  # match ':page' => 'static#show', :constraints => {:page => /about|ks_tests|ks_tests_ajax_target|ks_tests_malformed_target/}
  #
  # We use this only for Ponzu framework related pages.
  #
  # Document pages use the docs controller instead of static.
  match ':page' => 'static#show', :as => :static, 
        :constraints => {:page => /ponzu_frame|ponzu_admin_frame|rake_reports/}

  # /ks_cache_version
  match 'system/ks_cache_version' => "conferences#ks_cache_version", :as => :ks_cache_version

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
  root :to => 'static#layout'
  # root :to => 'dashboard#index'
  # root :to => redirect("/#{I18n.locale}")

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
