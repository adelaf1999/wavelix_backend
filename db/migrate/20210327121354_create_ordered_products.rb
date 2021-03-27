class CreateOrderedProducts < ActiveRecord::Migration[6.0]


  def change

    drop_table :ordered_products

    create_table :ordered_products do |t|
      t.integer :product_id, null: false
      t.integer :quantity, null: false
      t.decimal :price, null: false
      t.string :currency, null: false
      t.json :product_options, default: {}
      t.string :name, null: false
      t.timestamps
    end
  end


end
