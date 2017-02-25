Rails.application.routes.draw do

  namespace :fusor do
    namespace :api do
      namespace :v21 do

        resources :deployments, only: [:index, :show, :create, :update] do
          member do
            put :deploy
            put :redeploy
            get :validate
            get :validate_cdn
            get :log
            get :openshift_disk_space
            get :check_mount_point
            get :compatible_cpu_families
          end
        end

        resources :organizations, only: [:index, :show] do
          get :subscriptions, on: :member
        end
        resources :lifecycle_environments, only: [:index, :show, :create]
        resources :hostgroups, only: [:index, :show]
        resources :domains, only: [:index, :show]
        resources :settings, only: [:index]

        resources :discovered_hosts, only: [:index] do
          put :rename, :on => :member
        end

        scope :path => :customer_portal, :module => :customer_portal, :as => :customer_portal do
          match '/login' => 'customer_portal_proxies#login', :via => :post
          match '/logout' => 'customer_portal_proxies#logout', :via => :post
          match '/is_authenticated' => 'customer_portal_proxies#is_authenticated', :via => :get

          match '/users/:login/owners' => 'customer_portal_proxies#get', :via => :get, :as => :proxy_users_owners_path, :constraints => { :login => /\S+/ }
          match '/owners/:id/consumers' => 'customer_portal_proxies#get', :via => :get, :as => :proxy_owners_consumers_path
          match '/consumers' => 'customer_portal_proxies#post', :via => :post, :as => :proxy_consumer_create_path
          match '/consumers/:id' => 'customer_portal_proxies#get', :via => :get, :as => :proxy_consumer_show_path
          match '/pools' => 'customer_portal_proxies#get', :via => :get, :as => :proxy_pools_path
          match '/consumers/:id/entitlements' => 'customer_portal_proxies#get', :via => :get, :as => :proxy_consumer_entitlements_path
          match '/consumers/:id/entitlements' => 'customer_portal_proxies#post', :via => :post, :as => :proxy_consumer_entitlements_post_path
          match '/consumers/:id/entitlements' => 'customer_portal_proxies#delete', :via => :delete, :as => :proxy_consumer_entitlements_delete_path
          match '/consumers/:id/export' => 'customer_portal_proxies#export', :via => :get, :as => :proxy_consumer_export_path
        end

      end
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
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
