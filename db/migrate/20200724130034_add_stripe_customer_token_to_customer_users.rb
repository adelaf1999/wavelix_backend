class AddStripeCustomerTokenToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :customer_users, :stripe_customer_token, :string
  end
end
