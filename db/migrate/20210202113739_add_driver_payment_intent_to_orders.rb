class AddDriverPaymentIntentToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :driver_payment_intent, :string
  end
end
