class AddStoreAndCustomerNameToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :store_name, :string, null: false
    add_column :orders, :customer_name, :string, null: false
  end
end
