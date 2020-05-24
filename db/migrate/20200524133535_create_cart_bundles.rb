class CreateCartBundles < ActiveRecord::Migration[6.0]
  def change


    create_table :cart_bundles do |t|
      t.integer :cart_id, null: false
      t.integer :store_user_id, null: false
      t.text :delivery_location
      t.integer :order_type
      t.timestamps
    end

    remove_column :cart_items, :cart_id
    remove_column :cart_items, :delivery_location
    remove_column :cart_items, :order_type
    remove_column :cart_items, :store_user_id

    add_column :cart_items, :cart_bundle_id, :integer, null: false



  end
end
