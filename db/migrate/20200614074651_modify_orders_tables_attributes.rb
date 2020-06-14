class ModifyOrdersTablesAttributes < ActiveRecord::Migration[6.0]
  def change


    remove_column :orders, :store_fulfilled_order
    remove_column :orders, :driver_received_order
    remove_column :orders, :customer_received_order
    remove_column :orders, :driver_fulfilled_order
    remove_column :orders, :driver_arrived_to_store
    remove_column :orders, :driver_arrived_to_delivery_location
    remove_column :orders, :delivery_time_limit
    remove_column :orders, :driver_canceled_order

    add_column :orders, :store_fulfilled_order, :boolean
    add_column :orders, :driver_received_order, :boolean
    add_column :orders, :customer_received_order, :boolean
    add_column :orders, :driver_fulfilled_order, :boolean
    add_column :orders, :driver_arrived_to_store, :boolean
    add_column :orders, :driver_arrived_to_delivery_location, :boolean
    add_column :orders, :delivery_time_limit, :time
    add_column :orders, :driver_canceled_order, :boolean

  end
end
