class ChangeCartModels < ActiveRecord::Migration[6.0]
  def change

    drop_table :cart_bundles

    remove_column :cart_items, :cart_bundle_id

    add_column :cart_items, :cart_id, :integer, null: false

    add_column :cart_items, :store_user_id, :integer, null: false


  end
end
