class CartController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper

  def check_cart_delivery_location

    # error_codes

    # { 0: INVALID_DELIVERY_LOCATION, 1:  ITEMS_OUTSIDE_DELIVERABLE_ZONE}

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

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

                          distance = calculate_distance_km(delivery_location, store_user.store_address )

                          if distance <= 100


                            if distance > 25

                              if @delivery_options[store_user.id].nil?

                                @delivery_options[store_user.id] = {
                                    store_name: store_user.store_name,
                                    options: { 1 => 'Exclusive Delivery' }
                                }

                              end


                            else


                              if @delivery_options[store_user.id].nil?

                                @delivery_options[store_user.id] = {
                                    store_name: store_user.store_name,
                                    options: { 0 => 'Standard Delivery', 1 => 'Exclusive Delivery' }
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


    end

  end


  def delete_cart_item

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

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


  def get_cart_items

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      @cart_items = []

      @home_address = customer_user.home_address

      cookies.encrypted[:cart_id] = cart.id

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

                      if cart_item.quantity > product.stock_quantity

                        cart_item.update!(quantity: product.stock_quantity)

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


    end

  end


  private

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
        product_name: product.name
    }

  end

  def is_number?(arg)

    arg.is_a?(Numeric)

  end

end
