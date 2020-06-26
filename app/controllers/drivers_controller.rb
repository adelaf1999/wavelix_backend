class DriversController < ApplicationController

  include OrderHelper

  before_action :authenticate_user!


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

                Delayed::Job.enqueue(
                    StoreArrivalJob.new(order.id),
                    queue: 'store_arrival_job_queue',
                    priority: 0,
                    run_at: store_arrival_time_limit
                )

              else

                store_arrival_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 40.minutes).to_datetime

                order.update!(store_arrival_time_limit: store_arrival_time_limit)

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
