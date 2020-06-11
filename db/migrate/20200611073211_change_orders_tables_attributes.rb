class ChangeOrdersTablesAttributes < ActiveRecord::Migration[6.0]

  def change

    remove_column :orders, :drivers_confirmed
    remove_column :orders, :delivery_price
    remove_column :orders, :delivery_currency
    remove_column :orders, :order_type

    add_column :orders, :drivers_rejected, :string, array: true, default: []
    add_column :orders, :unconfirmed_drivers, :string, array: true, default: []
    add_column :orders, :delivery_fee, :decimal
    add_column :orders, :delivery_fee_currency, :string, default: 'USD'
    add_column :orders, :order_type, :integer # Can be nil if store handles delivery
    add_column :orders, :store_confirmation_status, :integer, default: 0 # {0: store_unconfirmed, 1: store_rejected, 2: store_accepted}

    add_column :orders, :store_fulfilled_order, :boolean, default: false # Store gave product(s) to driver
    add_column :orders, :driver_received_order, :boolean, default: false # Driver received product(s) from Store
    add_column :orders, :customer_received_order, :boolean, default: false # Customer received product(s) from Driver
    add_column :orders, :driver_fulfilled_order, :boolean, default: false # Driver gave products(s) to Customer

    add_column :orders, :driver_arrived_to_store, :boolean, default: false
    add_column :orders, :driver_arrived_to_delivery_location, :boolean, default: false
    add_column :orders, :store_handles_delivery, :boolean, null: false
    add_column :orders, :store_arrival_time_limit, :time # can be nil for stores that handle delivery
    add_column :orders, :delivery_time_limit, :time, null: false
    add_column :orders, :driver_canceled_order, :boolean, default: false
    add_column :orders, :customer_canceled_order, :boolean, default: false
    add_column :orders, :order_canceled_reason, :string, default: ''



  end

end
