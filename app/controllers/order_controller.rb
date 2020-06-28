class OrderController < ApplicationController

  include OrderHelper
  include MoneyHelper

  before_action :authenticate_user!


  def customer_cancel_order

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      order = customer_user.orders.find_by(id: params[:order_id])

      if order != nil

        if order.pending? &&  order.store_unconfirmed?

          @success = true

          order.canceled!

          order.update!(order_canceled_reason: 'Customer canceled order', customer_canceled_order: true)

          send_store_orders(order)

          # Send orders to customer_user channel

          # Notify store that order was canceled by the customer

          # Notify customer that the order has been canceled and that he will be refunded the full amount paid

          # Refund customer the full amount he paid

        else


          @success = false

        end

      else

        @success = false

      end


    end

  end


  def driver_fulfill_order

    # error_codes

    #  {0: ORDER_CANCELED_ERROR, 1: ORDER_COMPLETE_ERROR, 2: ORDER_ALREADY_FULFILLED_ORDER_ERROR }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      order = customer_user.orders.find_by(id: params[:order_id])

      if order != nil

        if !order.store_handles_delivery

          if order.ongoing?

            driver_fulfilled_order = order.driver_fulfilled_order

            if driver_fulfilled_order

              @success = false
              @error_code = 2

            else

              driver_fulfilled_order_code = params[:driver_fulfilled_order_code]

              if order.driver_fulfilled_order_code == driver_fulfilled_order_code && order.store_fulfilled_order

                @success = true

                order.update!(driver_fulfilled_order: true)

                order.complete!

                send_store_orders(order)

                # Send orders to customer_user channel

                # Send orders to driver channel

                # Notify store that order successful and amount has been successfully deposited to their balance

                # Notify driver that order successful and amount has been successfully deposited to their balance

                increment_store_balance(order)

                driver = Driver.find_by(id: order.driver_id)

                delivery_fee = order.delivery_fee

                delivery_fee_currency = order.delivery_fee_currency

                driver_currency = driver.currency

                if driver_currency == delivery_fee_currency

                  driver.increment!(:balance, delivery_fee)

                else

                  exchange_rates = get_exchange_rates(driver_currency)

                  delivery_fee = delivery_fee / exchange_rates[delivery_fee_currency]

                  driver.increment!(:balance, delivery_fee)

                end


              else

                @success = false


              end

            end

          else

            if order.canceled?

              @success = false
              @error_code = 0

            elsif order.pending?

              @success = false

            elsif order.complete?

              @success = false
              @error_code = 1

            end


          end

        else

          @success = false

        end

      else

        @success = false

      end

    end

  end

  def store_fulfill_order

    # error_codes

    #  {0: ORDER_CANCELED_ERROR, 1: ORDER_COMPLETE_ERROR, 2: ORDER_ALREADY_FULFILLED_ORDER_ERROR }

    # {3: ORDER_ASSIGNED_TO_ANOTHER_DRIVER }

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      order = store_user.orders.find_by(id: params[:order_id])

      if order != nil

        if !order.store_handles_delivery

          if order.ongoing?

            store_fulfilled_order = order.store_fulfilled_order

            if store_fulfilled_order

              @success = false
              @error_code = 2


            else

              drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

              driver_id = params[:driver_id]

              if is_positive_integer?(driver_id)

                driver_id = driver_id.to_i

                if drivers_canceled_order.include?(driver_id) || order.driver_id != driver_id

                  @success = false
                  @error_code = 3

                else

                  driver_received_order_code = params[:driver_received_order_code]

                  if order.driver_received_order_code == driver_received_order_code

                    @success = true

                    order.update!(store_fulfilled_order: true)

                    if order.exclusive?

                      driver = Driver.find_by(id: order.driver_id)

                      has_sensitive_products = store_user.has_sensitive_products

                      delivery_location = order.delivery_location

                      driver_location = { latitude: driver.latitude, longitude: driver.longitude }

                      distance = calculate_distance_meters(driver_location, delivery_location)

                      if distance <= 50

                        order.update!(driver_arrived_to_delivery_location: true)

                        # Notify store that driver almost arrived to customer delivery location

                        # Notify customer that the driver almost arrived to delivery location and has picked up their products

                        send_store_orders(order)

                        # Send orders to customer_user channel

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

                      else


                        delivery_loc_lat = delivery_location[:latitude]

                        delivery_loc_lng = delivery_location[:longitude]

                        estimated_arrival_time = estimated_arrival_time_minutes(
                            driver.latitude,
                            driver.longitude,
                            delivery_loc_lat,
                            delivery_loc_lng
                        )

                        # Notify customer that the driver has picked up their products


                        if has_sensitive_products

                          delivery_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 20.minutes).to_datetime

                          order.update!(delivery_time_limit: delivery_time_limit)

                          send_store_orders(order)

                          # Send orders to customer_user channel

                          # Send orders to driver channel

                          Delayed::Job.enqueue(
                              CustomerDeliveryJob.new(order.id),
                              queue: 'customer_delivery_job_queue',
                              priority: 0,
                              run_at: delivery_time_limit
                          )

                        else

                          delivery_time_limit = (DateTime.now.utc + estimated_arrival_time.minutes + 40.minutes).to_datetime

                          order.update!(delivery_time_limit: delivery_time_limit)

                          send_store_orders(order)

                          # Send orders to customer_user channel

                          # Send orders to driver channel

                          Delayed::Job.enqueue(
                              CustomerDeliveryJob.new(order.id),
                              queue: 'customer_delivery_job_queue',
                              priority: 0,
                              run_at: delivery_time_limit
                          )


                        end


                      end


                    else

                      delivery_time_limit = (DateTime.now.utc + 36.hours).to_datetime

                      order.update!(delivery_time_limit: delivery_time_limit)

                      send_store_orders(order)

                      # Send orders to customer_user channel

                      # Send orders to driver channel

                      Delayed::Job.enqueue(
                          CustomerDeliveryJob.new(order.id),
                          queue: 'customer_delivery_job_queue',
                          priority: 0,
                          run_at: delivery_time_limit
                      )


                    end

                  else

                    @success = false

                  end

                end



              else

                @success = false

              end


            end

          else

            if order.canceled?

              @success = false
              @error_code = 0

            elsif order.pending?

              @success = false

            elsif order.complete?

              @success = false
              @error_code = 1

            end

          end


        else

          @success = false

        end

      else

        @success = false

      end

    end

  end


  def accept_order

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      order_id = params[:order_id]

      order = store_user.orders.find_by(id: order_id)

      if order != nil

        if order.pending? && order.store_unconfirmed?

          if order.store_handles_delivery

            time_unit = params[:time_unit] # { 0: minutes, 1: hours: 2: days }

            time = params[:time]

            if time != nil && time_unit != nil

              if is_delivery_time_limit_valid?(time, time_unit)

                time = time.to_d

                time_unit = time_unit.to_i

                if time_unit == 0

                  delivery_time_limit = (DateTime.now.utc).to_datetime + (time).minutes

                elsif time_unit == 1

                  delivery_time_limit = (DateTime.now.utc).to_datetime + (time).hours

                else

                  delivery_time_limit = (DateTime.now.utc).to_datetime + (time).days

                end

                order.ongoing!

                order.store_accepted!

                order.update!(delivery_time_limit: delivery_time_limit)

                send_store_orders(order)

                # Send orders to customer_user channel

                # Notify customer that their order was accepted by store


                # After the x amount of time the store promised to do the delivery

                # The customer can choose to confirm or open a dispute

                # After 24 hours if the customer took no action the order will be completed

                # And the store balance will be incremented

                Delayed::Job.enqueue(
                    StoreDeliveryTimeJob.new(order_id),
                    queue: 'store_delivery_time_job_queue',
                    priority: 0,
                    run_at: delivery_time_limit + 24.hours
                )



              end

            end

          else


            order.store_accepted!

            send_store_orders(order)

            # Send orders to customer_user channel

            # Notify customer that their order was accepted by store

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


          end

        end

      end

    end

  end


  def reject_order

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      order_id = params[:order_id]

      order = store_user.orders.find_by(id: order_id)

      if order != nil

        if order.pending? && order.store_unconfirmed?

          @success = true

          order.canceled!

          order.store_rejected!

          order.products.each do |ordered_product|

            ordered_product = eval(ordered_product)

            product = Product.find_by(id: ordered_product[:id])

            if (product != nil) && (product.stock_quantity != nil)

              stock_quantity = product.stock_quantity + ordered_product[:quantity]

              product.update!(stock_quantity: stock_quantity)

            end

          end

          order.update!(order_canceled_reason: 'Store canceled order')

          send_store_orders(order)

          # Send orders to customer_user channel

          # Notify customer that the store rejected the order and that they will be refunded with the full amount paid

          # Refund customer the full amount he paid

        else

          @success = false

        end

      else

        @success = false

      end

    end

  end

  def get_orders


    if current_user.store_user?


      store_user = StoreUser.find_by(store_id: current_user.id)

      @orders = get_store_orders(store_user)


    else



    end

  end


  def validate_delivery_location


    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        default_currency = customer_user.default_currency

        delivery_location = params[:delivery_location]

        product = Product.find_by(id: params[:product_id])

        if delivery_location != nil && product != nil

          delivery_location = eval(delivery_location)

          store_user = product.category.store_user

          if delivery_location.instance_of?(Hash) && !delivery_location.empty?

            latitude = delivery_location[:latitude]

            longitude = delivery_location[:longitude]

            if latitude != nil && longitude != nil

              if is_decimal_number?(latitude) && is_decimal_number?(longitude)

                latitude = latitude.to_d

                longitude = longitude.to_d

                # Make sure delivery location is in store country

                geo_location = Geocoder.search([latitude, longitude])

                if geo_location.size > 0

                  geo_location_country_code = geo_location.first.country_code

                  if geo_location_country_code == product.store_country

                    has_sensitive_products = store_user.has_sensitive_products

                    handles_delivery = store_user.handles_delivery

                    maximum_delivery_distance = store_user.maximum_delivery_distance

                    store_location = store_user.store_address

                    distance = calculate_distance_km(delivery_location, store_location )

                    if handles_delivery

                      if maximum_delivery_distance != nil

                        if distance <= maximum_delivery_distance

                          @success = true

                          @can_order = true

                        else

                          @success = false

                          @message = 'Delivery location outside deliverable zone'

                        end

                      else

                        @success = true

                        @can_order = true

                      end

                    else

                      if has_sensitive_products

                        if distance <= 7

                          # Only exclusive delivery available

                          # Tell that to customer and explanation about exclusive delivery

                          @success = true

                          @can_order = true


                          if default_currency == 'USD'

                            @delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                          else

                            @delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                            exchange_rates = get_exchange_rates(default_currency)

                            @delivery_fee =  @delivery_fee / exchange_rates['USD']

                          end

                          @order_type = 1


                        else

                          @success = false

                          @message = 'Delivery location outside deliverable zone'


                        end

                      else


                        if distance <= 100

                          @success = true


                          if distance > 25

                            # Only exclusive delivery available

                            # Tell that to customer and explanation about exclusive delivery

                            @can_order = true


                            if default_currency == 'USD'

                              @delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                            else

                              @delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                              exchange_rates = get_exchange_rates(default_currency)

                              @delivery_fee =  @delivery_fee / exchange_rates['USD']

                            end

                            @order_type = 1



                          else

                            @can_order = false # Its false since customer has to choose which delivery option he wants


                            if default_currency == 'USD'

                              standard_delivery_fee = calculate_standard_delivery_fee_usd(distance)

                              exclusive_delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                              @delivery_options = [
                                  { order_type: 0, label: 'Standard Delivery', delivery_fee: standard_delivery_fee },
                                  { order_type: 1, label: 'Exclusive Delivery',delivery_fee: exclusive_delivery_fee }
                              ]


                            else

                              standard_delivery_fee = calculate_standard_delivery_fee_usd(distance)

                              exclusive_delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                              exchange_rates = get_exchange_rates(default_currency)

                              standard_delivery_fee =  standard_delivery_fee / exchange_rates['USD']

                              exclusive_delivery_fee =  exclusive_delivery_fee / exchange_rates['USD']


                              @delivery_options = [
                                  { order_type: 0, label: 'Standard Delivery', delivery_fee: standard_delivery_fee },
                                  { order_type: 1, label: 'Exclusive Delivery',delivery_fee: exclusive_delivery_fee }
                              ]

                            end


                          end


                        else

                          @success = false
                          @message = 'Delivery location outside deliverable zone'

                        end


                      end


                    end


                  else

                    @success = false
                    @message = 'Delivery location outside store country'

                  end


                else

                  @success = false
                  @message = 'Delivery location outside deliverable zone'

                end

              end

            end


          end


        end

      else

        @success = false

      end


    end

  end


  def place_order

    # error_codes

    #  {0: PRODUCT_NOT_AVAILABLE, 1: OUT_OF_STOCK_ERROR, 2: QUANTITY_ORDERED_GT_STOCK_QUANTITY}

    # { 3: INVALID_PRODUCT_OPTIONS, 4: INVALID_DELIVERY_LOCATION, 5: STORE_CLOSED_ERROR  }

    if current_user.customer_user?


      valid = true

      req_params = [:product_id, :quantity, :delivery_location]


      req_params.each do |p|

        if params[p] == nil || params[p].empty?

          valid = false

          break

        end

      end

      if valid

        product = Product.find_by(id: params[:product_id])

        customer_user = CustomerUser.find_by(customer_id: current_user.id)

        if customer_user.phone_number_verified?

          if product != nil

            store_user = product.category.store_user

            if store_user.verified? && customer_user.country == product.store_country

              # Product stock quantity can be nil

              if !product.product_available

                @success = false
                @error_code = 0
                @product = product.to_json

              elsif product.stock_quantity == 0

                @success = false
                @error_code = 1
                @product = product.to_json

              else

                quantity = params[:quantity]


                if is_quantity_valid?(quantity, product)

                  quantity = quantity.to_i

                  product_options = params[:product_options] # optional

                  product_attributes = product.product_attributes

                  if product_attributes != nil && product_attributes.size > 0

                    if product_options == nil

                      @success = false

                      @error_code = 3

                      @product_options = {}

                      product_attributes.each do |key, value|

                        if value.instance_of?(Array)

                          value.prepend('Select option')

                          @product_options[key] = value

                        end

                      end

                      return


                    else

                      product_options = eval(product_options)

                      if !product_options.instance_of?(Hash) ||  product_options.size < product_attributes.size || product_options.size > product_attributes.size

                        @success = false

                        @error_code = 3

                        @product_options = {}

                        product_attributes.each do |key, value|

                          if value.instance_of?(Array)

                            value.prepend('Select option')

                            @product_options[key] = value

                          end

                        end

                        return

                      else

                        product_options_valid = true

                        product_options.each do |key, value|

                          key = key.to_sym

                          attribute_values = product_attributes[key]

                          if attribute_values == nil || !attribute_values.include?(value)

                            product_options_valid = false

                            break

                          end

                        end


                        if !product_options_valid

                          @success = false

                          @error_code = 3

                          @product_options = {}

                          product_attributes.each do |key, value|

                            if value.instance_of?(Array)

                              value.prepend('Select option')

                              @product_options[key] = value

                            end

                          end

                          return

                        end

                      end

                    end

                  else


                    product_options = nil


                  end


                  delivery_location = eval(params[:delivery_location])

                  if delivery_location.instance_of?(Hash)

                    latitude = delivery_location[:latitude]

                    longitude = delivery_location[:longitude]

                    if latitude != nil && longitude != nil

                      if is_decimal_number?(latitude) && is_decimal_number?(longitude)

                        latitude = latitude.to_d

                        longitude = longitude.to_d

                        # Make sure delivery location is in store country

                        geo_location = Geocoder.search([latitude, longitude])

                        if geo_location.size > 0

                          geo_location_country_code = geo_location.first.country_code

                          if geo_location_country_code == product.store_country

                            has_sensitive_products = store_user.has_sensitive_products

                            handles_delivery = store_user.handles_delivery

                            maximum_delivery_distance = store_user.maximum_delivery_distance

                            store_location = store_user.store_address

                            store_latitude = store_location[:latitude]

                            store_longitude = store_location[:longitude]

                            store_schedule = store_user.schedule

                            distance = calculate_distance_km(delivery_location, store_location )

                            if handles_delivery

                              if maximum_delivery_distance != nil

                                if distance <= maximum_delivery_distance


                                  @success = handles_delivery_order(
                                      has_sensitive_products,
                                      store_latitude,
                                      store_longitude,
                                      store_schedule,
                                      product,
                                      quantity,
                                      delivery_location,
                                      store_user,
                                      customer_user,
                                      geo_location_country_code,
                                      product_options
                                  )

                                  if !@success

                                    @error_code = 5

                                  end



                                else

                                  @success = false

                                  @error_code = 4

                                  @has_sensitive_products = has_sensitive_products

                                  @handles_delivery = handles_delivery

                                  @maximum_delivery_distance = maximum_delivery_distance


                                end

                              else

                                @success = handles_delivery_order(
                                    has_sensitive_products,
                                    store_latitude,
                                    store_longitude,
                                    store_schedule,
                                    product,
                                    quantity,
                                    delivery_location,
                                    store_user,
                                    customer_user,
                                    geo_location_country_code,
                                    product_options
                                )

                                if !@success

                                  @error_code = 5

                                end

                              end



                            else

                              if has_sensitive_products


                                if distance <= 7

                                  # Only exclusive delivery available


                                  @success = does_not_handle_delivery_order(
                                      1,
                                      store_schedule,
                                      product_options,
                                      delivery_location,
                                      store_user,
                                      customer_user,
                                      geo_location_country_code,
                                      product,
                                      quantity,
                                      store_location,
                                      distance
                                  )


                                  if !@success

                                    @error_code = 5

                                  end



                                else

                                  @success = false


                                end


                              else


                                if distance <= 100


                                  order_type = params[:order_type]

                                  if order_type != nil && is_order_type_valid?(order_type)

                                    order_type = order_type.to_i

                                    if order_type == 0

                                      if distance > 25

                                        @success = false

                                      else


                                        @success = does_not_handle_delivery_order(
                                            order_type,
                                            store_schedule,
                                            product_options,
                                            delivery_location,
                                            store_user,
                                            customer_user,
                                            geo_location_country_code,
                                            product,
                                            quantity,
                                            store_location,
                                            distance
                                        )


                                      end


                                    elsif order_type == 1

                                      @success = does_not_handle_delivery_order(
                                          order_type,
                                          store_schedule,
                                          product_options,
                                          delivery_location,
                                          store_user,
                                          customer_user,
                                          geo_location_country_code,
                                          product,
                                          quantity,
                                          store_location,
                                          distance
                                      )

                                      if !@success

                                        @error_code = 5

                                      end


                                    end



                                  else

                                    @success = false

                                  end




                                else

                                  @success = false

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


                    else

                      @success = false

                    end


                  else

                    @success = false

                  end


                else

                  @success = false
                  @error_code = 2
                  @product = product.to_json


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



      else

        @success = false

      end


    end

  end




  private




  def is_delivery_time_limit_valid?(time, time_unit)

    res1 = /^(?<num>\d+)$/.match(time_unit)

    if res1 == nil

      false

    else

      time_unit = time_unit.to_i

      if time_unit == 0 || time_unit == 1 || time_unit == 2

        res2 = /^\d+([.]\d+)?$/.match(time)

        if res2 == nil

          false

        else

          time = time.to_d

          if time == 0

            false

          else

            # { 0: minutes, 1: hours: 2: days }

            if time_unit == 0

              (time).minutes <= 30.days

            elsif time_unit == 1

              (time).hours <= 30.days

            elsif time_unit == 2

              (time).days <= 30.days

            end

          end

        end


      else

        false

      end

    end

  end


  def product_total_usd(product_price, product_currency, quantity)

    if product_currency == 'USD'

      product_price * quantity

    else

      exchange_rates = get_exchange_rates('USD')

      product_price = product_price / exchange_rates[product_currency]

      product_price * quantity


    end

  end

  def does_not_handle_delivery_order(
      order_type,
      store_schedule,
      product_options,
      delivery_location,
      store_user,
      customer_user,
      country_code,
      product,
      quantity,
      store_location,
      distance
  )


    store_latitude = store_location[:latitude]

    store_longitude = store_location[:longitude]

    timezone = Timezone.lookup(store_latitude, store_longitude)

    local_time = timezone.time_with_offset(Time.now)

    if order_type == 0


      # Order is created and remains pending until the store accepts or rejects the order the next day even if store closed

      # If the stock quantity of a product was not nil it will be decremented after an order is created

      ordered_product = {
          id: product.id,
          quantity: quantity,
          price: product.price,
          currency: product.currency,
          product_options: product_options,
          name: product.name
      }


      delivery_fee_usd = calculate_standard_delivery_fee_usd(distance)

      total_price_usd = product_total_usd(product.price, product.currency, quantity) + delivery_fee_usd


      # Charge customer credit card using total price usd and if successful create order else handle error

      Order.create!(
          products: [ordered_product],
          delivery_location: delivery_location,
          store_user_id: store_user.id,
          customer_user_id: customer_user.id,
          country: country_code,
          store_handles_delivery: false,
          order_type: order_type,
          delivery_fee: delivery_fee_usd,
          total_price: total_price_usd
      )


      if product.stock_quantity != nil

        stock_quantity = product.stock_quantity - quantity

        product.update!(stock_quantity: stock_quantity)

      end


      true



    elsif order_type == 1

      # If store is closed order is not created


      day =  store_schedule.days.find_by(week_day: get_day_of_week(local_time))

      if day.closed

        false

      else

        can_order_1 = true

        can_order_2 = true

        if day.open_at_1 != nil &&  day.close_at_1 != nil

          open_at = day.open_at_1.split(':')

          close_at  = day.close_at_1.split(':')

          open_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              open_at[0].to_i,
              open_at[1].to_i,
              open_at[2].to_i,
              local_time.utc_offset
          )

          close_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              close_at[0].to_i,
              close_at[1].to_i,
              close_at[2].to_i,
              local_time.utc_offset
          )


          can_order_1 = local_time >= open_time && local_time < close_time



        end


        if day.open_at_2 != nil &&  day.close_at_2 != nil

          open_at = day.open_at_2.split(':')

          close_at  = day.close_at_2.split(':')

          open_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              open_at[0].to_i,
              open_at[1].to_i,
              open_at[2].to_i,
              local_time.utc_offset
          )

          close_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              close_at[0].to_i,
              close_at[1].to_i,
              close_at[2].to_i,
              local_time.utc_offset
          )


          can_order_2 = local_time >= open_time && local_time < close_time

        end


        if can_order_1 || can_order_2


          # If the stock quantity of a product was not nil it will be decremented after an order is created

          ordered_product = {
              id: product.id,
              quantity: quantity,
              price: product.price,
              currency: product.currency,
              product_options: product_options,
              name: product.name
          }


          delivery_fee_usd = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

          total_price_usd = product_total_usd(product.price, product.currency, quantity) + delivery_fee_usd

          # Charge customer credit card using total price usd and if successful create order else handle error

          Order.create!(
              products: [ordered_product],
              delivery_location: delivery_location,
              store_user_id: store_user.id,
              customer_user_id: customer_user.id,
              country: country_code,
              store_handles_delivery: false,
              order_type: order_type,
              delivery_fee: delivery_fee_usd,
              total_price: total_price_usd
          )




          if product.stock_quantity != nil

            stock_quantity = product.stock_quantity - quantity

            product.update!(stock_quantity: stock_quantity)

          end


          true


        else

          false

        end



      end


    end



  end


  def handles_delivery_order(
      has_sensitive_products,
      store_latitude,
      store_longitude,
      store_schedule,
      product,
      quantity,
      delivery_location,
      store_user,
      customer_user,
      country_code,
      product_options
  )


    timezone = Timezone.lookup(store_latitude, store_longitude)

    local_time = timezone.time_with_offset(Time.now)

    if has_sensitive_products

      # If store is closed order is not created

      day =  store_schedule.days.find_by(week_day: get_day_of_week(local_time))

      if day.closed

        false

      else

        can_order_1 = true

        can_order_2 = true

        if day.open_at_1 != nil &&  day.close_at_1 != nil

          open_at = day.open_at_1.split(':')

          close_at  = day.close_at_1.split(':')

          open_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              open_at[0].to_i,
              open_at[1].to_i,
              open_at[2].to_i,
              local_time.utc_offset
          )

          close_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              close_at[0].to_i,
              close_at[1].to_i,
              close_at[2].to_i,
              local_time.utc_offset
          )


          can_order_1 = local_time >= open_time && local_time < close_time



        end


        if day.open_at_2 != nil &&  day.close_at_2 != nil

          open_at = day.open_at_2.split(':')

          close_at  = day.close_at_2.split(':')

          open_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              open_at[0].to_i,
              open_at[1].to_i,
              open_at[2].to_i,
              local_time.utc_offset
          )

          close_time = Time.new(
              local_time.year,
              local_time.month,
              local_time.day,
              close_at[0].to_i,
              close_at[1].to_i,
              close_at[2].to_i,
              local_time.utc_offset
          )


          can_order_2 = local_time >= open_time && local_time < close_time

        end


        if can_order_1 || can_order_2


          # If the stock quantity of a product was not nil it will be decremented after an order is created

          ordered_product = {
              id: product.id,
              quantity: quantity,
              price: product.price,
              currency: product.currency,
              product_options: product_options,
              name: product.name
          }


          total_price_usd = product_total_usd(product.price, product.currency, quantity)

          # Charge customer credit card using total price usd and if successful create order else handle error

          Order.create!(
              products: [ordered_product],
              delivery_location: delivery_location,
              store_user_id: store_user.id,
              customer_user_id: customer_user.id,
              country: country_code,
              store_handles_delivery: true,
              total_price: total_price_usd
          )


          if product.stock_quantity != nil

            stock_quantity = product.stock_quantity - quantity

            product.update!(stock_quantity: stock_quantity)

          end


          true


        else

          false

        end



      end


    else

      # Order is created and remains pending until the store accepts or rejects the order the next day even if store closed

      # If the stock quantity of a product was not nil it will be decremented after an order is created


      ordered_product = {
          id: product.id,
          quantity: quantity,
          price: product.price,
          currency: product.currency,
          product_options: product_options,
          name: product.name
      }

      total_price_usd = product_total_usd(product.price, product.currency, quantity)


      # Charge customer credit card using total price usd and if successful create order else handle error

      Order.create!(
          products: [ordered_product],
          delivery_location: delivery_location,
          store_user_id: store_user.id,
          customer_user_id: customer_user.id,
          country: country_code,
          store_handles_delivery: true,
          total_price: total_price_usd
      )


      if product.stock_quantity != nil

        stock_quantity = product.stock_quantity - quantity

        product.update!(stock_quantity: stock_quantity)

      end


      true


    end




  end

  def get_day_of_week(local_time)


    if local_time.monday?
      'monday'
    elsif local_time.tuesday?
      'tuesday'
    elsif local_time.wednesday?
      'wednesday'
    elsif local_time.thursday?
      'thursday'
    elsif local_time.friday?
      'friday'
    elsif local_time.saturday?
      'saturday'
    elsif local_time.sunday?
      'sunday'
    end

  end


  def is_positive_integer?(arg)

    # 1, 2, 3, 4

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil

      false

    else

      arg = arg.to_i

      arg != 0


    end

  end



  def is_quantity_valid?(quantity, product)

    res = /^(?<num>\d+)$/.match(quantity)

    if res == nil

      false

    else

      quantity = quantity.to_i

      if quantity == 0

        false

      else

        if product.stock_quantity != nil

          quantity <= product.stock_quantity

        else

          true

        end


      end



    end

  end

end