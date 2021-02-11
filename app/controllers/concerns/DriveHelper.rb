module DriveHelper

  include OrderHelper

  include NotificationsHelper



  def driver_accept_order_failure(order)

    order.canceled!

    order.update!(order_canceled_reason: 'Order has expired')

    send_store_orders(order)

    send_customer_orders(order)

    send_customer_notification(
        order,
        "Your order from #{order.get_store_name} has expired and a refund has been issued for your order",
        'Order has expired',
        {
            show_orders: true
        }
    )


    OrderMailer.delay.order_expired(order.get_customer_email, order.get_store_name)

  end


  def driver_accept_order_success(driver, order, payment_intent_id)

    resolve_time_limit = DateTime.now.utc + 7.days

    order.update!(driver_payment_intent: payment_intent_id, resolve_time_limit: resolve_time_limit)


    Delayed::Job.enqueue(
        UnresolvedUnsuccessfulOrderJob.new(order.id),
        queue: 'unresolved_unsuccessful_order_job_queue',
        priority: 0,
        run_at: resolve_time_limit - 5.days
    )


    Delayed::Job.enqueue(
        UnresolvedUnsuccessfulOrderJob.new(order.id),
        queue: 'unresolved_unsuccessful_order_job_queue',
        priority: 0,
        run_at: resolve_time_limit - 3.days
    )


    Delayed::Job.enqueue(
        UnresolvedUnsuccessfulOrderJob.new(order.id),
        queue: 'unresolved_unsuccessful_order_job_queue',
        priority: 0,
        run_at: resolve_time_limit - 1.day
    )



    driver.offline! # Can receive new order requests when he completes/picks up the products for the current order he has

    driver_location = {latitude: driver.latitude, longitude: driver.longitude}

    store_user = StoreUser.find_by(id: order.store_user_id)

    has_sensitive_products = store_user.has_sensitive_products

    store_location = store_user.store_address

    store_latitude = store_location[:latitude]

    store_longitude = store_location[:longitude]

    distance = calculate_distance_meters(driver_location, store_location)

    order.update!(driver_id: driver.id)

    order.ongoing!

    send_driver_notification(
        order,
        'Make sure to get the QR code of the order scanned on your phone in the store before you leave',
        nil,
        {
            show_driver_orders: true
        }
    )


    send_store_notification(
        order,
        "Driver was assigned to pickup the order for your customer #{order.get_customer_name}. Make sure to scan the order QR code on the driver's phone before the driver leaves",
        nil,
        {
            show_orders: true
        }
    )


    OrderMailer.delay.driver_assigned_order(order.get_store_email, order.get_customer_name)


    estimated_arrival_time = estimated_arrival_time_minutes(
        driver.latitude,
        driver.longitude,
        store_latitude,
        store_longitude
    )


    if distance <= 100

      order.update!(driver_arrived_to_store: true)

      if distance >= 20

        send_customer_notification(
            order,
            "Driver is about to arrive to #{order.get_store_name} to pickup your order"
        )

        send_store_notification(
            order,
            "Make sure the order for your customer #{order.get_customer_name} is ready",
            'Driver is about to arrive',
            {
                show_orders: true
            }
        )


      end

    end


    if has_sensitive_products

      if estimated_arrival_time > 5

        store_arrival_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 20.minutes).to_datetime

      else

        store_arrival_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 30.minutes).to_datetime

      end

      order.update!(store_arrival_time_limit: store_arrival_time_limit)

      send_store_orders(order)

      send_customer_orders(order)

      send_driver_orders(driver)

      Delayed::Job.enqueue(
          StoreArrivalJob.new(order.id),
          queue: 'store_arrival_job_queue',
          priority: 0,
          run_at: store_arrival_time_limit
      )

    else

      store_arrival_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 40.minutes).to_datetime

      order.update!(store_arrival_time_limit: store_arrival_time_limit)

      send_store_orders(order)

      send_customer_orders(order)

      send_driver_orders(driver)

      Delayed::Job.enqueue(
          StoreArrivalJob.new(order.id),
          queue: 'store_arrival_job_queue',
          priority: 0,
          run_at: store_arrival_time_limit
      )

    end

  end

end