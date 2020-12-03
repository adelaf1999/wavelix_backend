Rails.application.routes.draw do

  mount StripeEvent::Engine, at: '/stripe-webhooks'


  mount_devise_token_auth_for 'Customer', controllers: {
    registrations: 'auth/customers/registrations'
  }, at: 'customer_auth', :skip => [
    :sessions,
    :passwords,
    :confirmations,
    :unlocks,
    :omniauth_callbacks,
    :token_validations,
    :registrations
  ]

  mount_devise_token_auth_for 'Store', controllers: {
    registrations: 'auth/stores/registrations'
  }, at: 'store_auth', :skip => [
    :sessions,
    :passwords,
    :confirmations,
    :unlocks,
    :omniauth_callbacks,
    :token_validations,
    :registrations
  ]

  mount_devise_token_auth_for 'User', controllers: {
      confirmations: 'auth/users/confirmations',
      unlocks: 'auth/users/unlocks',
      passwords: 'auth/users/passwords',
      sessions: 'auth/users/sessions'
  },at: 'auth', :skip => [
      :registrations,
      :confirmations,
      :unlocks,
      :sessions
  ]

  mount_devise_token_auth_for 'Employee', controllers: {
      sessions: 'auth/employees/sessions'
  } , at: 'employee_auth', :skip => [
      :passwords,
      :confirmations,
      :unlocks,
      :registrations,
      :omniauth_callbacks
  ]


  mount_devise_token_auth_for 'Admin', controllers: {
      sessions: 'auth/admins/sessions',
      unlocks: 'auth/admins/unlocks'
  }, at: 'admin_auth', :skip => [
      :passwords,
      :confirmations,
      :registrations,
      :omniauth_callbacks
  ]

  devise_scope :user do
    get '/auth/confirmation' => "auth/users/confirmations#show", as: :user_confirmation
    post '/auth/confirmation' => "auth/users/confirmations#create"
    post '/auth/sign_in' => "auth/users/sessions#create", as: :user_session
    delete '/auth/sign_out' => "auth/users/sessions#destroy", as: :destroy_user_session
    get '/auth/unlock' => "auth/users/unlocks#show", as: :user_unlock
    post '/auth/unlock' => "auth/users/unlocks#create"
  end

  devise_scope :customer do
    post '/register-customer' => 'auth/customers/registrations#create'
  end

  devise_scope :store do
    post '/register-store' => 'auth/stores/registrations#create'
  end


  # CATEGORIES ROUTES

  post '/create-category' => 'categories#create'

  get '/get-categories' => 'categories#get_categories'

  patch '/change-category-name' => 'categories#change_category_name'

  post '/add-subcategory' => 'categories#add_subcategory'

  post '/store-has-category' => 'categories#store_has_category'

  # PRODUCTS ROUTES

  post '/create-product' => 'products#create'
  
  post '/get-products' => 'products#get_products'

  post '/search-product' => 'products#search_product'

  patch '/update-product' => 'products#update_product'

  post '/store-owns-product-check' => 'products#store_owns_product_check'

  patch '/remove-product-image' => 'products#remove_product_image'

  post '/import-products' => 'products#import_products'

  post '/view-product' => 'products#show'

  post '/search-all-products' => 'products#search_all_products'


  # PROFILE ROUTES

  get '/view-my-profile' => 'profile#view_my_profile'

  post '/view-user-profile' => 'profile#view_user_profile'

  post '/update-profile' => 'profile#update_profile'

  post '/search-follow' => 'profile#search_follow'

  post '/change-profile-settings' => 'profile#change_profile_settings'

  post '/remove-follower' => 'profile#remove_follower'

  # POST ROUTES

  post '/create-post' => 'post#create'

  post '/edit-profile-post' => 'post#edit_profile_post'

  post '/destroy-post' => 'post#destroy'

  post '/search-post-products' => 'post#search_post_products'

  post '/add-story-post-viewer' => 'post#add_story_post_viewer'

  # SEARCH ROUTES

  post '/search-users' => 'search#search_users'

  post '/search-stores' => 'search#search_stores'

  post '/search-products' => 'search#search_products'

  post '/search-index' => 'search#index'

  # Follow Routes

  post '/follow-user' => 'follow#follow'

  post '/unfollow-user' => 'follow#unfollow'

  post '/cancel-follow-request' => 'follow#cancel_follow_request'

  post '/set-follow-request-status' => 'follow#set_follow_request_status'

  # Comment Routes

  post '/create-comment' => 'comment#create'

  post '/destroy-comment' => 'comment#destroy'

  # Like Routes

  post '/create-like' => 'likes#create'

  post '/destroy-like' => 'likes#destroy'

  # Currencies Routes

  get '/get-currencies' => 'currencies#currencies'

  # Order Routes

  post '/place-order' => 'order#place_order'

  post '/validate-delivery-location' => 'order#validate_delivery_location'

  get '/get-orders' => 'order#get_orders'

  post '/reject-order' => 'order#reject_order'

  post '/accept-order' => 'order#accept_order'

  post '/store-fulfill-order' => 'order#store_fulfill_order'

  post '/driver-fulfill-order' => 'order#driver_fulfill_order'

  post '/customer-cancel-order' => 'order#customer_cancel_order'

  post '/customer-confirm-order' => 'order#customer_confirm_order'

  post '/search-store-orders' => 'order#search_store_orders'

  post '/add-tracking-information' => 'order#add_tracking_information'


  # Cart Routes

  post '/add-cart' => 'cart#add'

  post '/get-cart-items' => 'cart#get_cart_items'

  post '/delete-cart-item' => 'cart#delete_cart_item'

  post '/check-cart-delivery-location' => 'cart#check_cart_delivery_location'

  post '/get-stores-fees' => 'cart#get_stores_fees'

  post '/place-orders' => 'cart#place_orders'

  # Customer Settings Routes

  get '/customer-settings' => 'customer_settings#index'

  post '/change-default-currency' => 'customer_settings#change_default_currency'

  patch '/update-building-name' => 'customer_settings#update_building_name'

  patch '/update-apartment-floor' => 'customer_settings#update_apartment_floor'

  patch '/update-home-address' => 'customer_settings#update_home_address'

  # Stores Routes

  get '/get-store-currency' => 'stores#get_store_currency'

  # Store Settings Routes

  get '/store-settings' => 'store_settings#index'

  post '/set-maximum-delivery-distance' => 'store_settings#set_maximum_delivery_distance'

  get '/toggle-handles-delivery' => 'store_settings#toggle_handles_delivery'

  # Phone verifications Routes

  get '/is-phone-number-verified' => 'phone_verifications#is_phone_number_verified'

  post '/request-phone-verification' => 'phone_verifications#create'

  post '/validate-phone-verification' => 'phone_verifications#verify'

  post '/can-request-sms' => 'phone_verifications#can_request_sms'

  # Drivers Routes

  post '/register-driver' => 'driver#register'

  get '/driver-index' => 'driver#index'

  get '/driver-profile-picture' => 'driver#profile_picture'

  # Drive Routes

  post '/cancel-order' => 'drive#cancel_order'

  post '/update-location' => 'drive#update_location'

  post '/accept-order-request' => 'drive#accept_order_request'

  post '/decline-order-request' => 'drive#decline_order_request'

  post '/can-pickup-order' => 'drive#can_pickup_order'

  get '/driver-go-offline' => 'drive#driver_go_offline'

  get '/driver-orders' => 'drive#driver_orders'


  # Payments Routes

  post '/add-card' => 'payments#add_card'

  delete '/destroy-card' => 'payments#destroy_card'

  get '/check-card-setup' => 'payments#check_card_setup'

  # Balances Routes

  get '/store-balances' => 'balances#store_balances'

  get '/driver-balances' => 'balances#driver_balances'

  # Employee Routes

  post '/create-employee' => 'employee#create'

  post '/toggle-employee-status' => 'employee#toggle_status'

  post '/change-employee-password' => 'employee#change_password'

  get '/employee-index' => 'employee#index'

  post '/update-employee-roles' => 'employee#update_roles'

  post '/search-store-employees' => 'employee#search'

  # Employee Portal Routes

  get '/employee-portal-index' => 'employee_portal#index'

  get '/employee-portal-home' => 'employee_portal#home'

  # Notifications Route

  post '/set-push-token' => 'notifications#set_push_token'

  # Shop Routes

  post '/shop-index' => 'shop#index'

  post '/search-shop-products' => 'shop#search_shop_products'

  post '/browse-category-products' => 'shop#browse_category_products'

  # Home Routes

  get '/home' => 'home#index'

  post '/get-profile-posts' => 'home#get_profile_posts'

  # List Routes

  post '/create-list' => 'list#create'

  post '/toggle-list-product' => 'list#toggle_list_product'

  post '/edit-list' => 'list#edit_list'

  post '/remove-list' => 'list#remove_list'

  post '/remove-list-product' => 'list#remove_list_product'

  get '/get-customer-lists' => 'list#index'

  post '/view-list' => 'list#show'

  # Recaptcha Routes

  post '/verify-recaptcha-token' => 'recaptcha#verify_recaptcha_token'

  # Admin Auth Routes

  post '/check-admin-email' => 'admin_auth#check_email'

  post '/resend-admin-verification-code' => 'admin_auth#resend_verification_code'

  # Admin Home Routes

  get '/admin-home-index' => 'admin_home#index'

  get '/get-admin-roles' => 'admin_home#get_roles'

  post '/change-my-admin-email' => 'admin_home#change_email'

  post '/change-my-admin-password' => 'admin_home#change_password'

  # Admin Accounts

  post '/create-admin-account' => 'admin_accounts#create'

  post '/view-admin-account' => 'admin_accounts#view_admin_account'

end
