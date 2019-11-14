Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'

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


  devise_scope :customer do
    post '/register-customer' => 'auth/customers/registrations#create'
  end

end
