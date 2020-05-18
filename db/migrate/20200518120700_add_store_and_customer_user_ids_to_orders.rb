class AddStoreAndCustomerUserIdsToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :store_user_id, :integer, null: false
    add_column :orders, :customer_user_id, :integer, null: false
    remove_column :orders, :store_id
    remove_column :orders, :customer_id
  end
end
