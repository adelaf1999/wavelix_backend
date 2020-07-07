class DriveController < ApplicationController

  include OrderHelper

  include MoneyHelper

  before_action :authenticate_user!

  def cancel_order

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        order = driver.orders.find_by(id: params[:order_id])

        if order != nil

          if order.ongoing? && !order.store_fulfilled_order

            @success = true

            get_new_driver(order)

            # Notify customer/store that driver canceled order and that we will be getting a new driver soon

          end

        else

          @success = false

        end

      else

        @success = false

      end


    end

  end


  def update_location

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        latitude = params[:latitude]

        longitude = params[:longitude]

        if latitude != nil && longitude != nil

          if is_decimal_number?(latitude) && is_decimal_number?(longitude)

            @success = true

            latitude = latitude.to_d

            longitude = longitude.to_d

            driver.update!(latitude: latitude, longitude: longitude)

            # Send driver location to customer and store user channels

            orders = driver.orders.where(status: 2, driver_arrived_to_store: false, store_fulfilled_order: false)

            orders.each do |order|

              driver_location = {latitude: latitude, longitude: longitude}

              store_user = StoreUser.find_by(id: order.store_user_id)

              has_sensitive_products = store_user.has_sensitive_products

              store_location = store_user.store_address

              distance = calculate_distance_meters(driver_location, store_location)

              if distance <= 50

                order.update!(driver_arrived_to_store: true)

                # Notify store that driver has arrived to store

                # Notify customer that driver has arrived to pick up their products

                send_store_orders(order)

                send_customer_orders(order)

                # Send orders to driver channel


                if has_sensitive_products

                  Delayed::Job.enqueue(
                      PickupOrderJob.new(order.id),
                      queue: 'pickup_order_job_queue',
                      priority: 0,
                      run_at: 20.minutes.from_now
                  )


                else

                  Delayed::Job.enqueue(
                      PickupOrderJob.new(order.id),
                      queue: 'pickup_order_job_queue',
                      priority: 0,
                      run_at: 40.minutes.from_now
                  )


                end


              end


            end


            orders = driver.orders.where(
                status: 2,
                driver_arrived_to_delivery_location: false,
                driver_fulfilled_order: false,
                store_fulfilled_order: true,
                order_type: 1
            )

            orders.each do |order|

              store_user = StoreUser.find_by(id: order.store_user_id)

              has_sensitive_products = store_user.has_sensitive_products

              driver_location = {latitude: latitude, longitude: longitude}

              delivery_location = order.delivery_location

              distance = calculate_distance_meters(driver_location, delivery_location)

              if distance <= 50

                # Notify store that driver has arrived to customer delivery location

                # Notify customer that the driver has arrived to delivery location

                order.update!(driver_arrived_to_delivery_location: true)

                send_store_orders(order)

                send_customer_orders(order)

                # Send orders to driver channel


                if has_sensitive_products

                  Delayed::Job.enqueue(
                      DeliverOrderJob.new(order.id),
                      queue: 'deliver_order_job_queue',
                      priority: 0,
                      run_at: 20.minutes.from_now
                  )



                else

                  Delayed::Job.enqueue(
                      DeliverOrderJob.new(order.id),
                      queue: 'deliver_order_job_queue',
                      priority: 0,
                      run_at: 40.minutes.from_now
                  )


                end


              end


            end


          else

            @success = false

          end

        else

          @success = false

        end


      else

        @success = false

      end


    end

  end

  def accept_order_request


    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.drivers_rejected.map(&:to_i)

          unconfirmed_drivers = order.unconfirmed_drivers.map(&:to_i)

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == current_driver.id && !drivers_rejected.include?(current_driver.id)

            @success = true

            if unconfirmed_drivers.include?(current_driver.id)

              unconfirmed_drivers.delete(current_driver.id)

              order.update!(unconfirmed_drivers: unconfirmed_drivers)

            end

            driver_location = {latitude: current_driver.latitude, longitude: current_driver.longitude}

            store_user = StoreUser.find_by(id: order.store_user_id)

            has_sensitive_products = store_user.has_sensitive_products

            store_location = store_user.store_address

            store_latitude = store_location[:latitude]

            store_longitude = store_location[:longitude]

            distance = calculate_distance_meters(driver_location, store_location)

            order.update!(driver_id: current_driver.id)

            order.ongoing!

            if distance <= 50

              order.update!(driver_arrived_to_store: true)

              # Notify store that driver has arrived to store

              # Notify customer that driver has arrived to pick up their products

              if has_sensitive_products

                Delayed::Job.enqueue(
                    PickupOrderJob.new(order.id),
                    queue: 'pickup_order_job_queue',
                    priority: 0,
                    run_at: 20.minutes.from_now
                )

                # Send orders to driver channel


              else

                Delayed::Job.enqueue(
                    PickupOrderJob.new(order.id),
                    queue: 'pickup_order_job_queue',
                    priority: 0,
                    run_at: 40.minutes.from_now
                )

                # Send orders to driver channel


              end


            else

              estimated_arrival_time = estimated_arrival_time_minutes(
                  current_driver.latitude,
                  current_driver.longitude,
                  store_latitude,
                  store_longitude
              )

              if has_sensitive_products

                store_arrival_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 20.minutes).to_datetime

                order.update!(store_arrival_time_limit: store_arrival_time_limit)

                send_store_orders(order)

                send_customer_orders(order)

                # Send orders to driver channel

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

                # Send orders to driver channel

                Delayed::Job.enqueue(
                    StoreArrivalJob.new(order.id),
                    queue: 'store_arrival_job_queue',
                    priority: 0,
                    run_at: store_arrival_time_limit
                )

              end


            end


          else

            @success = false

          end



        else

          @success = false

        end

      else

        @success = false

      end



    end

  end

  def decline_order_request

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.drivers_rejected.map(&:to_i)

          unconfirmed_drivers = order.unconfirmed_drivers.map(&:to_i)

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == current_driver.id && !drivers_rejected.include?(current_driver.id)

            @success = true

            if unconfirmed_drivers.include?(current_driver.id)

              unconfirmed_drivers.delete(current_driver.id)

              order.update!(unconfirmed_drivers: unconfirmed_drivers)

            end

            drivers_rejected.push(current_driver.id)

            order.update!(drivers_rejected: drivers_rejected)

            # Send orders to driver channel

            store_user = StoreUser.find_by(id: order.store_user_id)

            has_sensitive_products = store_user.has_sensitive_products

            store_location = store_user.store_address

            store_latitude = store_location[:latitude]

            store_longitude = store_location[:longitude]

            if has_sensitive_products

              drivers_has_sensitive_products(order, store_user, store_latitude, store_longitude)

            else

              if order.exclusive?

                drivers_exclusive_delivery(order, store_user, store_latitude, store_longitude)

              else

                drivers_standard_delivery(order, store_user, store_latitude, store_longitude)

              end

            end



          else

            @success = false

          end

        else

          @success = false

        end

      else

        @success = false

      end

    end

  end



end
