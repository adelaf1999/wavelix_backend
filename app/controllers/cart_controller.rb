class CartController < ApplicationController

  before_action :authenticate_user!


  def get_cart_bundles

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      cookies.encrypted[:cart_id] = cart.id

      @cart_bundles = []

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

        @cart_bundles.push({
                               cart_bundle_id: cart_bundle.id,
                               delivery_location: cart_bundle.delivery_location,
                               order_type: cart_bundle.order_type,
                               cart_items: cart_items,
                               store_name: store_user.store_name,
                               store_logo: store_profile.profile_picture.url
                           })



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

              # send cart item to cart channel

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
