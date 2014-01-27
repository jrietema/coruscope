Coruscope::Application.routes.draw do

  devise_for :users,
             :path => 'admin'

  devise_scope :admin do
    get "sign_in", :to => "admin/sessions#new"
    get "sign_out", :to => "admin/sessions#destroy"
  end

  comfy_route :cms_admin, :path => '/admin'

  scope :module => :admin do
    namespace :cms, as: :admin_cms, path: 'admin', :except => [:show, :new] do
      resources :sites do
        resources :groups do
          get :files,     on: :collection
          get :snippets,  on: :collection
          get :images,    on: :collection
        end
      end
      get 'sites/:site_id/file/groups/new', to: 'groups#new', as: :new_file_group, defaults: { grouped_type: 'Cms::File'}
      get 'sites/:site_id/snippet/groups/new', to: 'groups#new', as: :new_snippet_group, defaults: { grouped_type: 'Cms::Snippet'}
    end
  end

  namespace :cms do
    resources :contact_forms do
      resources :contacts
    end
  end

  comfy_route :cms, :path => '/', :sitemap => false

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'admin#sites'

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
