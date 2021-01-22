class ModifyDriverTablesStripeCustomerTokenColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :drivers, :stripe_customer_token
    add_column :drivers, :stripe_customer_token, :string
  end
end
