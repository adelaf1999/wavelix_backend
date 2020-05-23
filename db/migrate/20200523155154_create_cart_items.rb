class CreateCartItems < ActiveRecord::Migration[6.0]

  def change

    change_column :carts, :customer_user_id, :integer, null: false

    create_table :cart_items do |t|
      t.integer :cart_id, null: false
      t.integer :product_id, null: false
      t.text :delivery_location, null: false
      t.integer :quantity, null: false
      t.integer :order_type, null: false
      t.text :product_options
      t.timestamps
    end

  end

end
