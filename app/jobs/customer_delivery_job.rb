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

      send_driver_orders(driver)

      ActionCable.server.broadcast 'unsuccessful_orders_channel', {
          new_driver: true
      }

      ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
          unsuccessful_orders: driver.get_unsuccessful_orders
      }


      Delayed::Job.enqueue(
          NotifyUnsuccessfulOrderJob.new(order.id),
          queue: 'notify_unsuccessful_order_job_queue',
          priority: 0,
          run_at: 1.hour.from_now
      )

    end




  end

end