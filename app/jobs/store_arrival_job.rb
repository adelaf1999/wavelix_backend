class StoreArrivalJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    store_fulfilled_order = order.store_fulfilled_order

    driver_arrived_to_store = order.driver_arrived_to_store

    if !driver_arrived_to_store && store_fulfilled_order

      order.update!(driver_arrived_to_store: true)

    elsif !driver_arrived_to_store && !store_fulfilled_order

      get_new_driver(order)

      # Notify store that a new driver will be assigned for the order because the previous driver failed to arrive to store on time

      # Notify driver that a new driver will be assigned for the order because he failed to arrive to store on time

      # Notify customer that a new driver will be assigned for the order because the previous failed to arrive to store on time

    end

  end

end