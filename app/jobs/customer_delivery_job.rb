class CustomerDeliveryJob < Struct.new(:order_id)

  include OrderHelper

  include PaymentsHelper

  def perform

    order = Order.find_by(id: order_id)

    driver_fulfilled_order = order.driver_fulfilled_order

    driver_arrived = order.driver_arrived_to_delivery_location


    if driver_fulfilled_order

      if !driver_arrived

        order.update!(driver_arrived_to_delivery_location: true)

      end

    else

      order.canceled!

      order.update!(order_canceled_reason: 'Driver did not fulfill order')

      send_store_orders(order)

      send_customer_orders(order)

      driver = Driver.find_by(id: order.driver_id)

      send_driver_orders(driver)

      # Block the driver account temporarily to investigate what happened with the order

      driver.update!(account_blocked: true)
      
      refund_order(order)






    end




  end

end