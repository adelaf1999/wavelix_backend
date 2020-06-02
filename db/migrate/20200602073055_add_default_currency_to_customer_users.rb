class AddDefaultCurrencyToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :customer_users, :default_currency, :string, default: 'USD'
  end
end
