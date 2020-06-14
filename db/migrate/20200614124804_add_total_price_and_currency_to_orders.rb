class AddTotalPriceAndCurrencyToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :total_price, :decimal, null: false
    add_column :orders, :total_price_currency, :string, default: 'USD'
  end
end
