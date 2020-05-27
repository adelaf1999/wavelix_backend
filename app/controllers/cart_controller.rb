class CartController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper


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
