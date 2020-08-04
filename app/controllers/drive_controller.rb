class DriveController < ApplicationController

  include OrderHelper

  include MoneyHelper

  before_action :authenticate_user!



  def driver_orders

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        @orders =  get_driver_orders(driver)

        @driver_id = driver.id

      end


    end

  end


  def driver_go_offline

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        driver_verified = driver.driver_verified

        if driver_verified && driver.online?

          driver.offline!

          # If driver has a pending order request add him to drivers rejected and find a new driver

          order = Order.find_by(driver_id: nil, status: 1, prospective_driver_id: driver.id)

          if order != nil

            drivers_rejected = order.drivers_rejected.map(&:to_i)

            if !drivers_rejected.include?(driver.id)

              drivers_rejected.push(driver.id)

              order.update!(drivers_rejected: drivers_rejected)

              FindNewDriverJob.perform_later(order.id)

            end

          end



        end

      end

    end

  end


  def can_pickup_order

    # error_codes

    #  {0: DRIVING_OUTSIDE_REGISTERED_COUNTRY, 1: HAS_INCOMPLETE_EXCLUSIVE_ORDER, 2: HAS_UNPICKED_STANDARD_ORDERS }

    # { 3: ACCOUNT_BLOCKED }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        driver_verified = driver.driver_verified

        if driver_verified

          latitude = params[:latitude]

          longitude = params[:longitude]

          if latitude != nil && longitude != nil

            if is_decimal_number?(latitude) && is_decimal_number?(longitude)

              latitude = latitude.to_d

              longitude = longitude.to_d

              geo_location = Geocoder.search([latitude, longitude])

              if geo_location.size > 0

                geo_location_country_code = geo_location.first.country_code

                if geo_location_country_code == driver.country

                  # Driver can pickup new order if he does not have any exclusive orders ongoing

                  # And does not have any ongoing standard orders that are not fulfilled by store

                  exclusive_orders = driver.orders.where(status: 2, order_type: 1)

                  standard_orders = driver.orders.where(status: 2, order_type: 0, store_fulfilled_order: false)

                  if exclusive_orders.length >  0 || standard_orders.length > 0

                    @success = false

                    if exclusive_orders.length > 0


                      @error_code = 1

                    else


                      @error_code = 2

                    end


                  else

                    if driver.account_blocked

                      @success = false

                      @error_code = 3

                    else

                      @success = true

                      driver.online!

                      driver.update!(latitude: latitude, longitude: longitude)

                    end




                  end



                else

                  @success = false

                  @error_code = 0

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


        else

          @success = false

        end


      else

        @success = false

      end


    end


  end



  def cancel_order

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        order = driver.orders.find_by(id: params[:order_id])

        if order != nil

          if order.ongoing? && !order.store_fulfilled_order

            # Notify customer/store that driver canceled order and that we will be getting a new driver soon

            @success = true

            order.pending!

            order.update!(
                driver_arrived_to_store: false,
                driver_id: nil,
                prospective_driver_id: nil,
                drivers_rejected: [],
                store_arrival_time_limit: nil,
                driver_fulfilled_order_code: SecureRandom.hex
            )

            drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

            drivers_canceled_order.push(driver.id)

            order.update!(drivers_canceled_order: drivers_canceled_order)

            send_store_orders(order)

            send_customer_orders(order)

            send_driver_orders(driver)

            FindNewDriverJob.perform_later(order.id)



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


            orders = driver.orders.where(status: 2, driver_arrived_to_store: false, store_fulfilled_order: false)

            orders.each do |order|

              driver_location = {latitude: latitude, longitude: longitude}

              store_user = StoreUser.find_by(id: order.store_user_id)

              store_location = store_user.store_address

              distance = calculate_distance_meters(driver_location, store_location)

              if distance <= 100

                order.update!(driver_arrived_to_store: true)

                if distance >= 20

                  # Notify store that driver is about to arrive to store

                  # Notify customer that driver is about to arrive to store to pick up their products

                end

                send_store_orders(order)

                send_customer_orders(order)

                send_driver_orders(driver)


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

              driver_location = {latitude: latitude, longitude: longitude}

              delivery_location = order.delivery_location

              distance = calculate_distance_meters(driver_location, delivery_location)

              if distance <= 100

                order.update!(driver_arrived_to_delivery_location: true)

                if distance >= 20

                  # Notify store that driver is about to arrive to customer delivery location

                  # Notify customer that the driver is about to arrive to delivery location

                end

                send_store_orders(order)

                send_customer_orders(order)

                send_driver_orders(driver)

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

      driver = customer_user.driver

      if driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.drivers_rejected.map(&:to_i)

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver.id && !drivers_rejected.include?(driver.id) && !driver.account_blocked

            @success = true

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


            # Notify driver not to forget to get the QR Code of the order scanned by the store so we know he arrived

            # And picked up the products within the time limit


            # Notify store that a driver was assigned for the order

            # And to scan the Order QR Code on the driver's phone when he arrives so we know they fulfilled the order



            estimated_arrival_time = estimated_arrival_time_minutes(
                driver.latitude,
                driver.longitude,
                store_latitude,
                store_longitude
            )


            if distance <= 100

              order.update!(driver_arrived_to_store: true)

              if distance >= 20

                # Notify store that driver is about to arrive

                # Notify customer that driver is about to arrive to pickup their products

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

      driver = customer_user.driver

      if driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.drivers_rejected.map(&:to_i)

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver.id && !drivers_rejected.include?(driver.id)

            @success = true

            drivers_rejected.push(driver.id)

            order.update!(drivers_rejected: drivers_rejected)

            ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                contacting_driver: false
            }


            FindNewDriverJob.perform_later(order.id)


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
