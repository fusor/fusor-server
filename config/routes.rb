Rails.application.routes.draw do

  namespace :fusor do
    namespace :api do
      namespace :v21 do

        resources :deployments, only: [:index, :show, :update] do
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
        resources :settings, only: [:index]

        resources :discovered_hosts, only: [:index] do
          put :rename, :on => :member
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
