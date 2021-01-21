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

      # Block the driver account temporarily if and only if account is unblocked to investigate what happened with the order

      driver = Driver.find_by(id: order.driver_id)

      driver.block_temporarily

      # Send flag to unsuccessful orders page to refresh page

      # Send the order to view driver unsuccessful orders page

    end




  end

end