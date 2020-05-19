class OrderController < ApplicationController


  before_action :authenticate_user!


  def checkout

    # error_codes

    #  {0: PRODUCT_NOT_AVAILABLE, 1: OUT_OF_STOCK_ERROR, 2: QUANTITY_ORDERED_GT_STOCK_QUANTITY}

    # { 3: DELIVERY_LOCATION_OUTSIDE_STORE_COUNTRY }

    if current_user.customer_user?

      product = Product.find_by(id: params[:product_id])

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if product != nil

        store_user = product.category.store_user

        if store_user.verified? && customer_user.country == product.store_country

          quantity = params[:quantity]


          if !product.product_available

            @success = false
            @error_code = 0
            @product = product.to_json

          elsif product.stock_quantity == 0

            @success = false
            @error_code = 1
            @product = product.to_json

          else


            if quantity != nil && !quantity.empty?

              if is_quantity_valid?(quantity, product)

                quantity = quantity.to_i


                product_options = params[:product_options]
                

                delivery_location = params[:delivery_location]


                if delivery_location != nil && !delivery_location.empty?

                  delivery_location = eval(delivery_location)


                  if delivery_location.instance_of?(Hash)


                    latitude = delivery_location[:latitude]

                    longitude = delivery_location[:longitude]

                    if latitude != nil && longitude != nil


                      if is_number?(latitude) && is_number?(longitude)

                        latitude = latitude.to_d

                        longitude = longitude.to_d

                        # Make sure delivery location is in store country

                        geo_location = Geocoder.search([latitude, longitude])

                        geo_location_country_code = geo_location.first.country_code

                        if geo_location_country_code == product.store_country

                          # The stock quantity will be decremented after an order is created

                          # If the order was pending after 15 minutes the stock quantity will be re-incremented

                          # And the order will be marked canceled

                          # Also when user cancels order quantity gets re-incremented too


                          ordered_product = {
                              id: product.id,
                              quantity: quantity,
                              price: product.price,
                              currency: product.currency,
                              product_options: product_options,
                              name: product.name
                          }

                          order = Order.create!(
                              products: [ordered_product],
                              delivery_location: delivery_location,
                              store_user_id: store_user.id,
                              customer_user_id: customer_user.id,
                              country: geo_location_country_code
                          )

                          stock_quantity = product.stock_quantity - quantity

                          product.update!(stock_quantity: stock_quantity)


                          Delayed::Job.enqueue(OrderJob.new(order.id), queue: 'order_check_queue', priority: 0, run_at: 15.minutes.from_now)


                          @success = true

                          @order = order.to_json


                        else

                          @success = false
                          @error_code = 3
                          @product = product.to_json

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


            else

              @success = false

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


  private



  def is_number?(arg)

    arg.is_a?(Numeric)

  end

  def is_quantity_valid?(quantity, product)

    res = /^(?<num>\d+)$/.match(quantity)

    if res == nil

      false

    else

      quantity = quantity.to_d

      if quantity == 0

        false

      else

        quantity <= product.stock_quantity

      end



    end

  end

end