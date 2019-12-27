Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', controllers: {
    confirmations: 'auth/users/confirmations',
    unlocks: 'auth/users/unlocks',
    passwords: 'auth/users/passwords'
  },at: 'auth', :skip => [
    :registrations,
    :confirmations,
    :sessions,
    :unlocks
  ]

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

  devise_scope :user do
    get '/auth/confirmation' => "auth/users/confirmations#show", as: :user_confirmation
    post '/auth/confirmation' => "auth/users/confirmations#create"
    post '/auth/sign_in' => "devise_token_auth/sessions#create", as: :user_session 
    delete '/auth/sign_out' => "devise_token_auth/sessions#destroy", as: :destroy_user_session
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

  post '/create-categories' => 'categories#create'

  get '/get-categories' => 'categories#get_categories'

  patch '/change-category-name' => 'categories#change_category_name'

  post '/add-subcategory' => 'categories#add_subcategory'

  # PRODUCTS ROUTES

  post '/create-product' => 'products#create'

end
