class DriveController < ApplicationController

  include OrderHelper

  include MoneyHelper

  include NotificationsHelper

  include PaymentsHelper

  include DriveHelper

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



  def can_pickup_order

    # error_codes

    #  {0: DRIVING_OUTSIDE_REGISTERED_COUNTRY, 1: HAS_INCOMPLETE_EXCLUSIVE_ORDER, 2: HAS_UNPICKED_STANDARD_ORDERS }

    # { 3: TEMPORARILY_BLOCKED, 4: PERMANENTLY_BLOCKED }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = customer_user.driver

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


                    if driver.unblocked?


                      if driver.payment_source_setup?

                        @success = true

                        driver.online!

                        driver.update!(latitude: latitude, longitude: longitude)

                      else

                        @success = false

                      end


                    elsif driver.temporarily_blocked?

                      @success = false

                      @error_code = 3

                    else

                      @success = false

                      @error_code = 4

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

    else

      @success = false


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

            @success = true

            order.pending!

            order.release_driver_funds

            order.update!(
                driver_arrived_to_store: false,
                driver_id: nil,
                prospective_driver_id: nil,
                drivers_rejected: [],
                store_arrival_time_limit: nil,
                driver_fulfilled_order_code: SecureRandom.hex,
                driver_payment_intent: nil,
                resolve_time_limit: nil
            )

            drivers_canceled_order = order.get_drivers_canceled_order

            drivers_canceled_order.push(driver.id)

            order.update!(drivers_canceled_order: drivers_canceled_order)


            send_store_orders(order)

            send_customer_orders(order)

            send_driver_orders(driver)


            FindNewDriverJob.perform_later(order.id)


            send_customer_notification(
                order,
                'A new driver will be contacted to pickup your order',
                'Driver canceled order',
                {
                    show_orders: true
                }
            )

            send_store_notification(
                order,
                "A new driver will be contacted to pickup the order for your customer #{order.get_customer_name}",
                'Driver canceled order',
                {
                    show_orders: true
                }
            )



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

                  send_customer_notification(
                      order,
                      "Driver is about to arrive to #{order.get_store_name} to pickup your order"
                  )

                  send_store_notification(
                      order,
                      "Make sure the order for your customer #{order.get_customer_name} is ready, and to scan the order QR code on the driver's phone before the driver leaves",
                      'Driver is about to arrive',
                      {
                          show_orders: true
                      }
                  )




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

                  send_customer_notification(
                      order,
                      "Make sure your order arrived well, and to scan the order QR code on driver's phone before the driver leaves your location",
                      'Driver is about to arrive',
                      {
                          show_orders: true
                      }
                  )


                  send_store_notification(
                      order,
                      "Driver is about to arrive to the location of your customer #{order.get_customer_name}",
                      nil,
                      {
                          show_orders: true
                      }
                  )


                  send_driver_notification(
                      order,
                      'If the customer was not there to scan the order QR code on your phone, make sure to contact them so they confirm the order from their phone before you leave',
                      nil,
                      {
                          show_driver_orders: true
                      }
                  )



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

    # error_codes

    # { 0: ACCEPT_ORDER_REQUEST_ERROR, 1: AUTHENTICATION_REQUIRED, 2: CARD_ERROR, 3: CAPTURE_ORDER_AMOUNT_ERROR }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = customer_user.driver

      if driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.get_drivers_rejected

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver.id && !drivers_rejected.include?(driver.id) && driver.unblocked? && driver.payment_source_setup?


            begin


              order_total = order.total_price.to_f.round(2)

              delivery_fee = order.delivery_fee.to_f.round(2)

              products_price = order_total - delivery_fee


              products_price = products_price * 100

              products_price = products_price.round.to_i


              stripe_customer_token = driver.stripe_customer_token

              payment_method_id = get_payment_method_id(stripe_customer_token)


              driver_payment_intent = authorize_amount_usd(
                  products_price,
                  stripe_customer_token,
                  payment_method_id,
                  {
                      charging_driver_card: true,
                      driver_id: driver.id,
                      order_id: order.id
                  }
              )


              result = Stripe::PaymentIntent.confirm(
                  driver_payment_intent.id,
                  {
                      return_url: Rails.env.production? ? ENV.fetch('CARD_AUTH_PRODUCTION_REDIRECT_URL') : ENV.fetch('CARD_AUTH_DEVELOPMENT_REDIRECT_URL'),
                      off_session: false
                  }
              )


              status = result.status

              if status == 'requires_capture'


                order_payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)


                if order_payment_intent.status == 'requires_capture'

                  if capture_order_payment_intent(order_payment_intent.id)

                    @success = true

                    driver_accept_order_success(driver, order, driver_payment_intent.id)

                  else

                    @success = false

                    @error_code = 3

                    @message = 'Order has been canceled.'

                    Stripe::PaymentIntent.cancel(driver_payment_intent.id)

                    driver_accept_order_failure(order)


                  end

                else

                  if order_payment_intent.status == 'succeeded'

                    @success = true

                    driver_accept_order_success(driver, order, driver_payment_intent.id)

                  else

                    @success = false

                    @error_code = 3

                    @message = 'Order has been canceled.'

                    Stripe::PaymentIntent.cancel(driver_payment_intent.id)

                    driver_accept_order_failure(order)

                  end

                end



              elsif status == 'requires_action' || result.next_action != nil

                @success = false

                @error_code = 1

                next_action = result.next_action

                @redirect_url = next_action.redirect_to_url.url


              else

                @success = false

                @message =  'Error authorizing amount from card. Please try again or change the card in the settings.'

                @error_code = 2

              end


            rescue Stripe::CardError => e

              @success = false

              @message =  e.error.message.blank? ? 'Error authorizing amount from card. Please try again or change the card in the settings.' :  e.error.message

              @error_code = 2


            rescue => e

              @success = false

              @message =  'Error authorizing amount from card. Please try again or change the card in the settings.'

              @error_code = 2

            end




          else

            @success = false

            @message = 'Error accepting order. Please try again later.'

            @error_code = 0

          end



        else

          @success = false

          @message = 'Error accepting order. Please try again later.'

          @error_code = 0

        end

      else

        @success = false

        @message = 'Error accepting order. Please try again later.'

        @error_code = 0

      end

    else

      @success = false

      @message = 'Error accepting order. Please try again later.'

      @error_code = 0

    end

  end

  def decline_order_request

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = customer_user.driver

      if driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.get_drivers_rejected

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
