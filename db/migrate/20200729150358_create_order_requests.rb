class CreateOrderRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :order_requests do |t|
      t.text :products, null: false, array: true
      t.text :delivery_location, null: false
      t.integer :store_user_id, null: false
      t.integer :customer_user_id, null: false
      t.string :country, null: false
      t.boolean :store_handles_delivery, null: false
      t.decimal :total_price, null: false
      t.string :total_price_currency, default: 'USD'
      t.integer :order_type
      t.decimal :delivery_fee
      t.string :delivery_fee_currency, default: 'USD'
      t.timestamps
    end
  end
end
