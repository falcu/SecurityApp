Rails.application.routes.draw do

  namespace :api do

    post "users/create", to: "users#create", as: "create"
    put "users/sign_in", to: "users#sign_in", as: "sign_in"
    post "users/create_or_sign_in", to: "users#create_or_sign_in", as: "create_or_sign_in"

    post "groups/create", to: "groups#create"
    put "groups/add", to: "groups#add", as: "add_member"
    put "groups/add_single_group", to: "groups#add_single_group", as: "add_single_group_member"
    put "groups/quit", to: "groups#quit", as: "quit_member"
    put "groups/rename", to: "groups#rename", as: "rename_group"
    put "groups/remove_members", to: "groups#remove_members", as: "remove_members"
    get "groups/group_information", to: "groups#group_information", as: "group_information"

    put "localities/notify", to: "localities#notify_locality", as: "notify_locality"
    put "localities/set_secure", to: "localities#set_secure_locality", as: "set_secure_locality"
    put "localities/set_insecure", to: "localities#set_insecure_locality", as: "set_insecure_locality"
    get "localities/get_localities", to: "localities#get_localities", as: "get_localities"
    get "localities/get_secure_localities", to: "localities#get_secure_localities", as: "get_secure_localities"
    get "localities/get_insecure_localities", to: "localities#get_insecure_localities", as: "get_insecure_localities"

    post "notifications/send", to: "notifications#send_notification", as: "send_notification"
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
