class CartController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper

  include MoneyHelper

  include PaymentsHelper



  def place_orders

    # error_codes

    # { 0: INVALID_STORES, 1: INVALID_CART_ITEMS, 2: CARD_AUTH_REQUIRED, 3: CARD_ERROR }

    if current_user.customer_user?

      required_params = [:stores_cart_items, :delivery_location]

      if required_params_valid?(required_params)

        customer_user = CustomerUser.find_by(customer_id: current_user.id)

        stores_cart_items = eval(params[:stores_cart_items])

        delivery_location = eval(params[:delivery_location])

        if customer_user.phone_number_verified? && customer_user.payment_source_setup?

          cart = customer_user.cart

          if stores_cart_items_valid?(stores_cart_items, cart)

            if are_stores_verified?(stores_cart_items)

              if is_delivery_location_valid?(delivery_location)

                # Validate that the customer and delivery location is in the store country

                delivery_loc_country = Geocoder.search([delivery_location[:latitude], delivery_location[:longitude]]).first.country_code

                customer_country = customer_user.country

                if cart_items_country_valid?(stores_cart_items, cart, customer_country, delivery_loc_country)

                  # The store may toggle between handling delivery or not

                  # The customer might not be able to order from store if closed in some cases

                  # Therefore we need to validate the stores and order types

                  @invalid_stores = {}

                  @invalid_store_user_ids = []

                  stores_cart_items = validate_stores(stores_cart_items, cart, delivery_location)

                  if stores_cart_items.size > 0


                    if @invalid_stores.size > 0

                      ActionCable.server.broadcast "cart_#{cart.id}_user_#{customer_user.customer_id}_channel", {
                          invalid_stores: @invalid_stores
                      }

                    end


                    stores_cart_items = validate_cart_items(stores_cart_items, cart)

                    if stores_cart_items.size > 0


                      order_request_ids = []

                      ordered_products_total_usd = 0

                      stores_cart_items.each do |store_cart_item|

                        store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

                        handles_delivery = store_user.handles_delivery

                        cart_item_ids = store_cart_item[:cart_item_ids]

                        total_price_usd = 0

                        ordered_products = []

                        cart_item_ids.each do |cart_item_id|

                          cart_item = cart.cart_items.find_by(id: cart_item_id)

                          product = Product.find_by(id: cart_item.product_id)

                          price = product.price

                          quantity = cart_item.quantity

                          total_price_usd += convert_amount(
                              price * quantity,
                              product.currency,
                              'USD'
                          )

                          ordered_product = {
                              id: product.id,
                              quantity: quantity,
                              price: price,
                              currency: product.currency,
                              product_options: cart_item.product_options,
                              name: product.name
                          }

                          ordered_products.push(ordered_product)


                        end


                        if handles_delivery

                          order_request = OrderRequest.create!(
                              products: ordered_products,
                              delivery_location: delivery_location,
                              store_user_id: store_user.id,
                              customer_user_id: customer_user.id,
                              country: store_user.store_country,
                              store_handles_delivery: true,
                              total_price: total_price_usd
                          )

                          order_request_ids.push(order_request.id)

                          ordered_products_total_usd += order_request.total_price


                        else

                          order_type = store_cart_item[:order_type].to_i

                          store_location = store_user.store_address

                          if order_type == 0

                            distance = calculate_distance_km(delivery_location, store_location )

                            delivery_fee_usd = calculate_standard_delivery_fee_usd(distance)

                            total_price_usd += delivery_fee_usd

                            order_request = OrderRequest.create!(
                                products: ordered_products,
                                delivery_location: delivery_location,
                                store_user_id: store_user.id,
                                customer_user_id: customer_user.id,
                                country: store_user.store_country,
                                store_handles_delivery: false,
                                order_type: order_type,
                                delivery_fee: delivery_fee_usd,
                                total_price: total_price_usd
                            )


                            order_request_ids.push(order_request.id)

                            ordered_products_total_usd += order_request.total_price



                          elsif order_type == 1

                            delivery_fee_usd = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )

                            total_price_usd += delivery_fee_usd

                            order_request = OrderRequest.create!(
                                products: ordered_products,
                                delivery_location: delivery_location,
                                store_user_id: store_user.id,
                                customer_user_id: customer_user.id,
                                country: store_user.store_country,
                                store_handles_delivery: false,
                                order_type: order_type,
                                delivery_fee: delivery_fee_usd,
                                total_price: total_price_usd
                            )


                            order_request_ids.push(order_request.id)

                            ordered_products_total_usd += order_request.total_price



                          end


                        end


                      end


                      charge_customer_card(
                          ordered_products_total_usd,
                          customer_user,
                          order_request_ids
                      )





                    else

                      @success = false
                      @error_code = 1

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


  end


  def get_stores_fees

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        cart = customer_user.cart

        stores_cart_items = params[:stores_cart_items]

        if stores_cart_items != nil

          stores_cart_items = eval(stores_cart_items)

          if stores_cart_items_valid?(stores_cart_items, cart)

            delivery_location = params[:delivery_location]

            if delivery_location != nil

              delivery_location = eval(delivery_location)


              if is_delivery_location_valid?(delivery_location)

                @success = true

                @total = 0

                customer_currency = customer_user.default_currency

                @currency = customer_currency

                @fees = []

                stores_cart_items.each do |store_cart_item|

                  fee = {}

                  store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

                  store_profile = store_user.store.profile

                  store_name = store_user.store_name

                  store_logo = store_profile.profile_picture.url

                  items_currency = store_user.currency

                  store_location = store_user.store_address

                  fee[:store_name] = store_name

                  fee[:store_logo] = store_logo


                  items_price = 0

                  cart_item_ids = store_cart_item[:cart_item_ids]

                  cart_item_ids.each do |cart_item_id|

                    cart_item = cart.cart_items.find_by(id: cart_item_id)

                    product = Product.find_by(id: cart_item.product_id)

                    price = product.price

                    quantity = cart_item.quantity

                    items_price += (price * quantity)


                  end



                  order_type = store_cart_item[:order_type]

                  if order_type != nil

                    order_type = order_type.to_i

                    distance = calculate_distance_km(delivery_location, store_location )

                    if order_type == 0

                      delivery_fee = calculate_standard_delivery_fee_usd(distance)


                    else

                      delivery_fee = calculate_exclusive_delivery_fee_usd(delivery_location, store_location )


                    end


                    items_price = convert_amount(items_price, items_currency, customer_currency )

                    delivery_fee = convert_amount(delivery_fee, 'USD', customer_currency)

                    total = items_price + delivery_fee

                    @total += total


                    fee[:items_price] = items_price

                    fee[:delivery_fee] = delivery_fee

                    fee[:total] = total

                    @fees.push(fee)


                  else

                    items_price = convert_amount(items_price, items_currency, customer_currency )

                    total = items_price

                    @total += total

                    fee[:items_price] = items_price

                    fee[:total] = total

                    @fees.push(fee)

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

    end


  end

  def check_cart_delivery_location

    # error_codes

    # { 0: INVALID_DELIVERY_LOCATION, 1:  ITEMS_OUTSIDE_DELIVERABLE_ZONE}

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        cart = customer_user.cart

        selected_cart_items = params[:selected_cart_items]

        if selected_cart_items != nil

          selected_cart_items = eval(selected_cart_items)

          if selected_cart_items.instance_of?(Array) && selected_cart_items.size > 0


            # If the cart item is not found it gets deleted from the selected cart items

            selected_cart_items.delete_if do |cart_item_id|

              cart_item = cart.cart_items.find_by(id: cart_item_id)

              cart_item == nil

            end


            ActionCable.server.broadcast "cart_#{cart.id}_user_#{current_user.id}_channel", {selected_cart_items: selected_cart_items}


            if selected_cart_items.size > 0


              delivery_location = params[:delivery_location]

              if delivery_location != nil

                delivery_location = eval(delivery_location)

                if delivery_location.instance_of?(Hash) && !delivery_location.empty?

                  latitude = delivery_location[:latitude]

                  longitude = delivery_location[:longitude]

                  if latitude != nil && longitude != nil

                    if is_number?(latitude) && is_number?(longitude)

                      latitude = latitude.to_d

                      longitude = longitude.to_d

                      # Make sure delivery location is in store country

                      geo_location = Geocoder.search([latitude, longitude])

                      if geo_location.size > 0


                        geo_location_country_code = geo_location.first.country_code

                        country_valid = true


                        # Check if all stores are in the country of the delivery location

                        selected_cart_items.each do |cart_item_id|

                          cart_item = cart.cart_items.find_by(id: cart_item_id)

                          store_user = StoreUser.find_by(id: cart_item.store_user_id)

                          if geo_location_country_code != store_user.store_country

                            @success = false
                            @error_code = 0
                            @message = 'Delivery location outside store(s) country'
                            country_valid = false
                            break

                          end

                        end

                        if country_valid


                          @outside_zone_items = []
                          @delivery_options = {}
                          outside_zone_stores = []
                          has_outside_zone_items = false

                          # Check if all stores are within deliverable zone from delivery location

                          selected_cart_items.each do |cart_item_id|

                            cart_item = cart.cart_items.find_by(id: cart_item_id)

                            store_user = StoreUser.find_by(id: cart_item.store_user_id)

                            store_profile = store_user.store.profile

                            handles_delivery = store_user.handles_delivery

                            has_sensitive_products = store_user.has_sensitive_products

                            distance = calculate_distance_km(delivery_location, store_user.store_address )


                            if handles_delivery

                              maximum_delivery_distance = store_user.maximum_delivery_distance

                              if maximum_delivery_distance != nil

                                if distance <= maximum_delivery_distance

                                  if @delivery_options[store_user.id].nil?

                                    @delivery_options[store_user.id] = {
                                        store_name: store_user.store_name,
                                        store_logo: store_profile.profile_picture.url,
                                        options: nil,
                                        handles_delivery: handles_delivery
                                    }

                                  end



                                else

                                  has_outside_zone_items = true

                                  @outside_zone_items.push(cart_item_id)

                                  if !outside_zone_stores.include?(store_user.store_name)

                                    outside_zone_stores.push(store_user.store_name)

                                  end


                                end

                              else


                                if @delivery_options[store_user.id].nil?

                                  @delivery_options[store_user.id] = {
                                      store_name: store_user.store_name,
                                      store_logo: store_profile.profile_picture.url,
                                      options: nil,
                                      handles_delivery: handles_delivery
                                  }

                                end



                              end



                            else


                              if has_sensitive_products

                                if distance <= 7

                                  # Only exclusive delivery available

                                  if @delivery_options[store_user.id].nil?


                                    @delivery_options[store_user.id] = {
                                        store_name: store_user.store_name,
                                        store_logo: store_profile.profile_picture.url,
                                        options: { 1 => 'Exclusive Delivery' },
                                        handles_delivery: handles_delivery
                                    }

                                  end


                                else

                                  has_outside_zone_items = true

                                  @outside_zone_items.push(cart_item_id)

                                  if !outside_zone_stores.include?(store_user.store_name)

                                    outside_zone_stores.push(store_user.store_name)

                                  end


                                end



                              else


                                if distance <= 100


                                  if distance > 25

                                    if @delivery_options[store_user.id].nil?


                                      @delivery_options[store_user.id] = {
                                          store_name: store_user.store_name,
                                          store_logo: store_profile.profile_picture.url,
                                          options: { 1 => 'Exclusive Delivery' },
                                          handles_delivery: handles_delivery
                                      }

                                    end


                                  else


                                    if @delivery_options[store_user.id].nil?

                                      @delivery_options[store_user.id] = {
                                          store_name: store_user.store_name,
                                          store_logo: store_profile.profile_picture.url,
                                          options: { 0 => 'Standard Delivery', 1 => 'Exclusive Delivery' },
                                          handles_delivery: handles_delivery
                                      }

                                    end

                                  end


                                else

                                  has_outside_zone_items = true

                                  @outside_zone_items.push(cart_item_id)

                                  if !outside_zone_stores.include?(store_user.store_name)

                                    outside_zone_stores.push(store_user.store_name)

                                  end

                                end


                              end



                            end


                          end



                          if has_outside_zone_items


                            @success = false


                            if @outside_zone_items.length == selected_cart_items.length

                              @error_code = 0

                              @message = 'Delivery location outside deliverable zone'

                            else

                              @error_code = 1

                              @message = 'Item(s) from the following store(s) are outside deliverable zone: '


                              outside_zone_stores.each do |store_name|
                                @message += ' ' + store_name + ','
                              end

                              @message.delete_suffix!(',')

                              @message += '. '

                              @message += 'Do you want to exclude them and continue?'



                            end





                          else


                            @success = true

                          end


                        end


                      else

                        @success = false
                        @error_code = 0
                        @message = 'Delivery location outside deliverable zone'


                      end

                    end

                  end


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


  def delete_cart_item

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        cart = customer_user.cart

        @cart_items = []

        cart_item = cart.cart_items.find_by(id: params[:cart_item_id])

        if cart_item != nil

          cart_item.destroy!

        end

        cart.cart_items.each do |item|

          @cart_items.push(get_cart_item(item))

        end

      end


    end

  end


  def get_cart_items

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        cart = customer_user.cart

        @cart_items = []

        @home_address = customer_user.home_address

        @cart_id = cart.id


        current_location = params[:current_location]

        if current_location != nil

          current_location = eval(current_location)

          if current_location.instance_of?(Hash)

            latitude = current_location[:latitude]

            longitude = current_location[:longitude]

            if latitude != nil && longitude != nil

              if is_number?(latitude) && is_number?(longitude)

                latitude = latitude.to_d

                longitude = longitude.to_d

                geo_location = Geocoder.search([latitude, longitude])

                if geo_location.size > 0

                  geo_location_country_code = geo_location.first.country_code

                  # Update customer country code and delete products not in country code

                  customer_user.update!(country: geo_location_country_code)

                  cart.cart_items.each do |cart_item|

                    product = Product.find_by(id: cart_item.product_id)

                    if product != nil

                      if !product.product_available

                        cart_item.destroy!

                      elsif product.stock_quantity == 0

                        cart_item.destroy!

                      elsif customer_user.country != product.store_country

                        cart_item.destroy!

                      else


                        if product.stock_quantity != nil

                          if cart_item.quantity > product.stock_quantity

                            cart_item.update!(quantity: product.stock_quantity)

                          end

                        end

                        @cart_items.push(get_cart_item(cart_item))


                      end

                    else

                      cart_item.destroy!

                    end

                  end

                  # Send cart items to cart channel


                end


              end

            end

          end

        end

      end


    end

  end

  def add

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        cart = customer_user.cart

        product = Product.find_by(id: params[:product_id])

        if product != nil

          if customer_user.country == product.store_country

            quantity = params[:quantity]

            if quantity != nil

              res = /^(?<num>\d+)$/.match(quantity)

              if res == nil || quantity.to_i == 0

                @success = false

              else

                quantity = quantity.to_i

                product_options = params[:product_options] # optional can be nil/empty

                if !product_options.blank?

                  begin

                    product_options = eval(product_options)

                    if !product_options.instance_of?(Hash) || product_options.size == 0

                      product_options = {}

                    end

                  rescue => e

                    product_options = {}

                  end



                else

                  product_options = {}

                end


                @success = true

                store_user = product.category.store_user

                CartItem.create!(
                    product_id: product.id,
                    quantity: quantity,
                    product_options: product_options,
                    cart_id: cart.id,
                    store_user_id: store_user.id
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


      else

        @success = false

      end


    end

  end


  private

  def charge_customer_card(total_price_usd, customer_user, order_request_ids )

    begin


      total_price_cents = total_price_usd * 100

      total_price_cents = total_price_cents.round.to_i

      stripe_customer_token = customer_user.stripe_customer_token

      payment_method_id = get_payment_method_id(stripe_customer_token)


      payment_intent = authorize_amount_usd(
          total_price_cents,
          stripe_customer_token,
          payment_method_id,
          {
              charging_customer_card: true,
              customer_user_id: customer_user.id,
              order_request_ids: order_request_ids.to_s
          }
      )

      result = Stripe::PaymentIntent.confirm(
          payment_intent.id,
          {
              return_url: Rails.env.production? ? ENV.fetch('CARD_AUTH_PRODUCTION_REDIRECT_URL') : ENV.fetch('CARD_AUTH_DEVELOPMENT_REDIRECT_URL'),
              off_session: false
          }
      )


      status = result.status

      if status == 'requires_capture'

        @success = true


      elsif status == 'requires_action' || result.next_action != nil

        @success = false

        @error_code = 2

        next_action = result.next_action

        @redirect_url = next_action.redirect_to_url.url



      elsif status == 'requires_payment_method'

        @success = false

      end



    rescue Stripe::CardError => e

      @success = false

      @error_code = 3

      if e.error.message

        @error_message =  e.error.message

      end

    rescue => e

      @success = false

    end






  end


  def validate_cart_items(stores_cart_items, cart)

    # Validate the product availability , stock quantity and the quantity of each item ordered by the customer

    stores_cart_items.each do |store_cart_item|

      store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

      store_profile = store_user.store.profile

      cart_item_ids = store_cart_item[:cart_item_ids]

      invalid_cart_item_ids = []

      cart_item_ids.each do |cart_item_id|

        cart_item = cart.cart_items.find_by(id: cart_item_id)

        product = Product.find_by(id: cart_item.product_id)

        if !product.product_available

          add_invalid_item(store_user, store_profile, product, 'Product is no longer available')

          invalid_cart_item_ids.push(cart_item_id)


        elsif product.stock_quantity != nil

          # Since product stock quantity is optional


          if product.stock_quantity == 0

            add_invalid_item(store_user, store_profile, product, 'Product is out of stock')

            invalid_cart_item_ids.push(cart_item_id)

          elsif cart_item.quantity > product.stock_quantity

            add_invalid_item(store_user, store_profile, product, 'Quantity ordered is greater than stock quantity')

            invalid_cart_item_ids.push(cart_item_id)


          end


        end


      end


      cart_item_ids.delete_if {|cart_item_id| invalid_cart_item_ids.include?(cart_item_id) }



    end


    stores_cart_items.delete_if {|store_cart_item| store_cart_item[:cart_item_ids].size == 0 }

    stores_cart_items



  end



  def validate_stores(stores_cart_items, cart, delivery_location)


    stores_cart_items.each do |store_cart_item|

      store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

      store_profile = store_user.store.profile

      order_type = store_cart_item[:order_type]

      if order_type == nil && !store_user.handles_delivery

        # Store toggled from handling delivery to not

        add_invalid_store(
            store_cart_item,
            cart,
            store_user,
            store_profile,
            'Store no longer provides delivery, you can re-order the products by paying a delivery fee.'
        )


      elsif order_type != nil && store_user.handles_delivery

        # Store toggled from  not handling delivery to handling delivery

        # Remove order type from store_cart_item

        store_cart_item.delete(:order_type)

        maximum_delivery_distance = store_user.maximum_delivery_distance


        if maximum_delivery_distance != nil

          store_location = store_user.store_address

          distance = calculate_distance_km(delivery_location, store_location )

          if distance > maximum_delivery_distance


            add_invalid_store(
                store_cart_item,
                cart,
                store_user,
                store_profile,
                'Store now handles delivery, but does not deliver to your location.'
            )

          end



        end


      else


        has_sensitive_products = store_user.has_sensitive_products

        handles_delivery = store_user.handles_delivery

        maximum_delivery_distance = store_user.maximum_delivery_distance

        store_location = store_user.store_address

        store_schedule = store_user.schedule

        distance = calculate_distance_km(delivery_location, store_location )


        if handles_delivery


          if maximum_delivery_distance != nil


            if distance <= maximum_delivery_distance

              can_place_order = handles_delivery_order(
                  has_sensitive_products,
                  store_schedule,
                  store_user
              )



              if !can_place_order

                add_invalid_store(
                    store_cart_item,
                    cart,
                    store_user,
                    store_profile,
                    'Store is closed'
                )

              end

            else


              add_invalid_store(
                  store_cart_item,
                  cart,
                  store_user,
                  store_profile,
                  'Store does not deliver to your location'
              )

            end


          else


            can_place_order = handles_delivery_order(
                has_sensitive_products,
                store_schedule,
                store_user
            )


            if !can_place_order

              add_invalid_store(
                  store_cart_item,
                  cart,
                  store_user,
                  store_profile,
                  'Store is closed'
              )

            end


          end


        else


          if has_sensitive_products


            if distance <= 7

              # Only exclusive delivery available

              can_place_order = does_not_handle_delivery_order(1, store_schedule, store_user)

              if !can_place_order

                add_invalid_store(
                    store_cart_item,
                    cart,
                    store_user,
                    store_profile,
                    'Store is closed'
                )

              end




            else

              add_invalid_store(
                  store_cart_item,
                  cart,
                  store_user,
                  store_profile,
                  'Delivery is not available to your location'
              )

            end


          else


            if distance <= 100


              order_type = order_type.to_i

              if order_type == 0


                if distance > 25

                  add_invalid_store(
                      store_cart_item,
                      cart,
                      store_user,
                      store_profile,
                      'Standard delivery is not available to your location'
                  )

                end


              elsif order_type == 1

                can_place_order = does_not_handle_delivery_order(order_type, store_schedule, store_user)

                if !can_place_order

                  add_invalid_store(
                      store_cart_item,
                      cart,
                      store_user,
                      store_profile,
                      'Store is closed'
                  )

                end


              end


            else

              add_invalid_store(
                  store_cart_item,
                  cart,
                  store_user,
                  store_profile,
                  'Delivery is not available to your location'
              )

            end



          end


        end





      end




    end



    stores_cart_items.delete_if {|store_cart_item| @invalid_store_user_ids.include?(store_cart_item[:store_user_id]) }

    stores_cart_items


  end



  def add_invalid_store(store_cart_item, cart, store_user, store_profile, reason)


    items = []

    cart_item_ids = store_cart_item[:cart_item_ids]

    cart_item_ids.each do |cart_item_id|

      cart_item = cart.cart_items.find_by(id: cart_item_id)

      product = Product.find_by(id: cart_item.product_id)

      items.push({
                     product_name: product.name ,
                     product_picture: product.main_picture.url
                 })


    end



    @invalid_stores[store_user.id] = {
        store_name: store_user.store_name,
        store_logo: store_profile.profile_picture.url,
        items: items,
        reason: reason
    }


    @invalid_store_user_ids.push(store_user.id)



  end


  def add_invalid_item(store_user, store_profile, product, reason)

    if @invalid_stores[store_user.id].nil?

      @invalid_stores[store_user.id] = {
          store_name: store_user.store_name,
          store_logo: store_profile.profile_picture.url,
          items: [
              {
                  product_name: product.name ,
                  product_picture: product.main_picture.url,
                  reason: reason
              }
          ]
      }

    else

      items = @invalid_stores[store_user.id][:items]

      items.push({
                     product_name: product.name ,
                     product_picture: product.main_picture.url,
                     reason: reason
                 })


      @invalid_stores[store_user.id][:items] = items


    end


  end


  def cart_items_country_valid?(stores_cart_items, cart, customer_country, delivery_loc_country)

    is_valid = true

    stores_cart_items.each do |store_cart_item|

      if is_valid

        cart_item_ids = store_cart_item[:cart_item_ids]

        cart_item_ids.each do |cart_item_id|

          cart_item = cart.cart_items.find_by(id: cart_item_id)

          product = Product.find_by(id: cart_item.product_id)

          if !(customer_country == product.store_country) || !(delivery_loc_country == product.store_country)

            is_valid = false

            break

          end


        end


      else

        break

      end


    end


    is_valid

  end


  def is_delivery_location_valid?(delivery_location)

    is_valid = true

    if delivery_location.instance_of?(Hash) && !delivery_location.empty?

      latitude = delivery_location[:latitude]

      longitude = delivery_location[:longitude]

      if latitude != nil && longitude != nil

        if is_decimal_number?(latitude) && is_decimal_number?(longitude)

          latitude = latitude.to_d

          longitude = longitude.to_d

          geo_location = Geocoder.search([latitude, longitude])

          if geo_location.size == 0

            is_valid = false

          end


        else

          is_valid = false

        end


      else

        is_valid = false

      end


    else

      is_valid = false

    end

    is_valid

  end


  def are_stores_verified?(stores_cart_items)

    is_valid = true

    stores_cart_items.each do |store_cart_item|

      store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

      if !store_user.verified?

        is_valid = false

        break

      end

    end

    is_valid


  end


  def stores_cart_items_valid?(stores_cart_items, cart)

    is_valid = true

    if stores_cart_items.instance_of?(Array) && stores_cart_items.size > 0


      stores_cart_items.each do |store_cart_item|

        if is_valid

          store_user = StoreUser.find_by(id: store_cart_item[:store_user_id])

          if store_user != nil


            # Validate Order Type if present

            order_type = store_cart_item[:order_type]

            if order_type != nil && !is_order_type_valid?(order_type)

              is_valid = false

              break

            end


            cart_item_ids = store_cart_item[:cart_item_ids]

            if cart_item_ids != nil


              if cart_item_ids.instance_of?(Array) && cart_item_ids.size > 0


                cart_item_ids.each do |cart_item_id|

                  cart_item = cart.cart_items.find_by(id: cart_item_id)

                  if cart_item != nil

                    if cart_item.store_user_id != store_user.id

                      is_valid = false

                      break

                    end


                  else

                    is_valid = false

                    break

                  end


                end


              else

                is_valid = false

                break

              end


            else

              is_valid = false

              break

            end


          else

            is_valid = false

            break

          end


        else

          break

        end


      end



    else

      is_valid = false

    end


    is_valid


  end

  def required_params_valid?(required_params)

    valid = true

    required_params.each do |p|

      if params[p] == nil || params[p].empty?

        valid = false

        break

      end

    end

    valid


  end

  def get_cart_item(cart_item)


    product = Product.find_by(id: cart_item.product_id)

    store_user = StoreUser.find_by(id: cart_item.store_user_id)

    store_profile = store_user.store.profile

    {
        cart_item_id: cart_item.id,
        quantity: cart_item.quantity,
        product_options: cart_item.product_options,
        store_name: store_user.store_name,
        product_picture: product.main_picture.url,
        store_logo: store_profile.profile_picture.url,
        stock_quantity: product.stock_quantity,
        product_name: product.name,
        store_user_id: store_user.id
    }

  end

  def is_number?(arg)

    arg.is_a?(Numeric)

  end

end
