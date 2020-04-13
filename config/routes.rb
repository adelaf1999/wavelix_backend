Rails.application.routes.draw do

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


  # PROFILE ROUTES

  get '/view-my-profile' => 'profile#view_my_profile'

  post '/update-profile' => 'profile#update_profile'

  post '/search-follow' => 'profile#search_follow'

  post '/change-profile-settings' => 'profile#change_profile_settings'

  # POST ROUTES

  post '/create-post' => 'post#create'

  # SEARCH ROUTES

  post '/search-users' => 'search#search_users'

  post '/search-stores' => 'search#search_stores'


end
