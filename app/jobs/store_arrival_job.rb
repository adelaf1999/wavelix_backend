class StoreArrivalJob < Struct.new(:order_id)

  include OrderHelper

  include NotificationsHelper

  def perform

    order = Order.find_by(id: order_id)

    store_fulfilled_order = order.store_fulfilled_order

    driver_arrived_to_store = order.driver_arrived_to_store

    if store_fulfilled_order

      if !driver_arrived_to_store

        order.update!(driver_arrived_to_store: true)

      end

    else

      get_new_driver(order)


      send_store_notification(
          order,
          "A new driver will pickup the order for your customer #{order.get_customer_name} because the previous driver did not arrive to the store on time",
          'New driver assigned'
      )



      send_driver_notification(
          order,
          "A new driver will be assigned to pickup the order from #{order.get_store_name} for #{order.get_customer_name} because store arrival time limit passed",
          'Store arrival time limit passed'
      )


      send_customer_notification(
          order,
          "A new driver will be assigned to pickup your order from #{order.get_store_name} because previous driver did not arrive to store on time",
          'New driver assigned'
      )



    end


  end

end