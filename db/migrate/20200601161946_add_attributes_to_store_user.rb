class AddAttributesToStoreUser < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :has_sensitive_products, :boolean, default: false
    add_column :store_users, :handles_delivery, :boolean, default: false
  end
end
