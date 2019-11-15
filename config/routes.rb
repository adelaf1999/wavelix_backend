Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', controllers: {
    confirmations: 'auth/users/confirmations'
  },at: 'auth', :skip => [
    :registrations,
    :confirmations,
    :sessions
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

  end

  devise_scope :customer do
    post '/register-customer' => 'auth/customers/registrations#create'
  end

  devise_scope :store do
    post '/register-store' => 'auth/stores/registrations#create'
  end

end
