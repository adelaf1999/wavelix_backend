class CartController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper


  def setup_cart_bundle

    # error_codes

    # { 0: CART_BUNDLE_NOT_FOUND }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      cart_bundle = cart.cart_bundles.find_by(id: params[:cart_bundle_id])

      if cart_bundle != nil

        if (cart_bundle.delivery_location.nil? ||  cart_bundle.delivery_location.empty? ) && cart_bundle.order_type == nil

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

                    store_user = StoreUser.find_by(id: cart_bundle.store_user_id)

                    if geo_location_country_code == store_user.store_country

                      distance = calculate_distance_km(delivery_location, store_user.store_address )

                      if distance <= 100

                        # Exclusive delivery is available up to 100 KM

                        # Standard delivery is only available if delivery location is within 25 KM of the store

                        order_type = params[:order_type]

                        if is_order_type_valid?(order_type)

                          order_type = order_type.to_i

                          if order_type == 0 && distance <= 25 || order_type == 1

                            @success = true

                            cart_bundle.update!(delivery_location: delivery_location, order_type: order_type)

                            @cart_bundles = customer_cart_bundles(cart)

                            ActionCable.server.broadcast "cart_#{cart.id}_customer_#{current_user.id}", {cart_bundles: @cart_bundles}

                          end


                        end

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

        @error_code = 0

        cart_bundles = customer_cart_bundles(cart)

        ActionCable.server.broadcast "cart_#{cart.id}_customer_#{current_user.id}", {cart_bundles: cart_bundles}

      end

    end

  end


  def validate_cart_bundle_location

    # error_codes

    # { 0: CART_BUNDLE_NOT_FOUND, 1: INVALID_DELIVERY_LOCATION }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      cart_bundle = cart.cart_bundles.find_by(id: params[:cart_bundle_id])

      if cart_bundle != nil

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

                  store_user = StoreUser.find_by(id: cart_bundle.store_user_id)


                  if geo_location_country_code == store_user.store_country

                    distance = calculate_distance_km(delivery_location, store_user.store_address )

                    if distance <= 100

                      @success = true


                      if distance > 25

                        @delivery_options = { 1 => 'Exclusive Delivery' }

                      else

                        @delivery_options = { 0 => 'Standard Delivery', 1 => 'Exclusive Delivery' }

                      end



                    else

                      @success = false

                      @error_code = 1

                      @message = 'Delivery location outside deliverable zone'

                    end


                  else

                    @success = false

                    @error_code = 1

                    @message =  'Delivery location outside store country'

                  end


                else

                  @success = false

                  @error_code = 1

                  @message = 'Delivery location outside deliverable zone'

                end

              end


            end

          end

        end


      else

        @success = false

        @error_code = 0

        cart_bundles = customer_cart_bundles(cart)

        ActionCable.server.broadcast "cart_#{cart.id}_customer_#{current_user.id}", {cart_bundles: cart_bundles}

      end


    end

  end

  def delete_cart_item


    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      cart_bundle = cart.cart_bundles.find_by(id: params[:cart_bundle_id])

      if cart_bundle != nil

        cart_item = cart_bundle.cart_items.find_by(id: params[:cart_item_id])

        if cart_item != nil


          if cart_bundle.cart_items.size == 1

            cart_bundle.destroy!

          else

            cart_item.destroy!

          end

          @success = true

          @cart_bundles = customer_cart_bundles(cart)

          ActionCable.server.broadcast "cart_#{cart.id}_customer_#{current_user.id}", {cart_bundles: @cart_bundles}


        else

          @success = false

        end

      else

        @success = false

      end


    end

  end


  def get_cart_bundles

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      cookies.encrypted[:cart_id] = cart.id

      @cart_bundles = customer_cart_bundles(cart)

      @home_address = customer_user.home_address


    end

  end

  def add

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

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

              if product_options != nil && !product_options.empty?

                product_options = eval(product_options)

                if !product_options.instance_of?(Hash) || product_options.size == 0

                  product_options = nil

                end

              else

                product_options = nil

              end

              @success = true

              store_user = product.category.store_user


              cart_bundle = CartBundle.find_by(store_user_id: store_user.id)

              if cart_bundle == nil


                new_cart_bundle = CartBundle.create!(cart_id: cart.id, store_user_id: store_user.id)

                CartItem.create!(
                    cart_bundle_id: new_cart_bundle.id,
                    product_id: product.id,
                    quantity: quantity,
                    product_options: product_options
                )

              else

                CartItem.create!(
                    cart_bundle_id: cart_bundle.id,
                    product_id: product.id,
                    quantity: quantity,
                    product_options: product_options
                )


              end


              @cart_bundles = customer_cart_bundles(cart)

              ActionCable.server.broadcast "cart_#{cart.id}_customer_#{current_user.id}", {cart_bundles: @cart_bundles}


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

  def is_number?(arg)

    arg.is_a?(Numeric)

  end

  def customer_cart_bundles(cart)

    cart_bundles = []

    cart.cart_bundles.each do |cart_bundle|

      cart_items = []

      cart_bundle.cart_items.each do |cart_item|

        product = Product.find_by(id: cart_item.product_id)

        if product != nil

          if !product.product_available || product.stock_quantity == 0

            cart_item.destroy!

          else

            if cart_item.quantity > product.stock_quantity

              cart_item.update!(quantity: product.stock_quantity)

            end

            cart_items.push({
                                product_name: product.name,
                                quantity: cart_item.quantity,
                                stock_quantity: product.stock_quantity,
                                product_options: cart_item.product_options,
                                picture: product.main_picture.url,
                                cart_item_id: cart_item.id
                            })

          end

        else

          cart_item.destroy!

        end

      end

      store_user = StoreUser.find_by(id: cart_bundle.store_user_id)
      store_profile = store_user.store.profile

      cart_bundles.push({
                            cart_bundle_id: cart_bundle.id,
                            delivery_location: cart_bundle.delivery_location,
                            order_type: cart_bundle.order_type,
                            cart_items: cart_items,
                            store_name: store_user.store_name,
                            store_logo: store_profile.profile_picture.url,
                            store_location: store_user.store_address
                        })



    end

    cart_bundles


  end

end
