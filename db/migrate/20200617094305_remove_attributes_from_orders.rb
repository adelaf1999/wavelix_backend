class RemoveAttributesFromOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :driver_received_order
    remove_column :orders, :customer_received_order
  end
end
