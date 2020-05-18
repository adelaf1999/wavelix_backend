class CreateOrders < ActiveRecord::Migration[6.0]

  def change

    create_table :orders do |t|
      t.text :products, array: true, null: false
      t.text :drivers_confirmed, array: true, default: []
      t.decimal :delivery_price, default: 0.0
      t.string :delivery_currency, default: 'USD'
      t.integer :driver_id
      t.integer :status, default: 0
      t.integer :store_id, null: false
      t.integer :customer_id, null: false
      t.text :delivery_location, null: false
      t.timestamps
    end


    drop_table :delivery_requests

  end

end
