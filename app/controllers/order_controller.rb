class OrderController < ApplicationController


  before_action :authenticate_user!


  def validate_delivery_location


    if current_user.customer_user?


      delivery_location = params[:delivery_location]

      product = Product.find_by(id: params[:product_id])


      if delivery_location != nil && product != nil


        delivery_location = eval(delivery_location)

        store_user = product.category.store_user

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

                if geo_location_country_code == product.store_country

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
                    @message = 'Delivery location outside deliverable zone'

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

    end


  end


  def checkout

    # error_codes

    #  {0: PRODUCT_NOT_AVAILABLE, 1: OUT_OF_STOCK_ERROR, 2: QUANTITY_ORDERED_GT_STOCK_QUANTITY}

    # { 3: DELIVERY_LOCATION_OUTSIDE_STORE_COUNTRY, 4: STORE_OUTSIDE_DELIVERY_ZONE, 5: STANDARD_DELIVERY_UNAVAILABLE }

    if current_user.customer_user?

      valid = true

      req_params = [:product_id, :quantity, :delivery_location, :order_type]


      req_params.each do |p|

        if params[p] == nil || params[p].empty?

          valid = false

          break

        end

      end


      if valid

        product = Product.find_by(id: params[:product_id])

        customer_user = CustomerUser.find_by(customer_id: current_user.id)

        if product != nil

          store_user = product.category.store_user

          if store_user.verified? && customer_user.country == product.store_country


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

                product_options = params[:product_options] # optional can be nil/empty

                if product_options != nil && !product_options.empty?

                  product_options = eval(product_options)

                  if !product_options.instance_of?(Hash) || product_options.size == 0

                    product_options = nil

                  end

                else

                  product_options = nil

                end

                delivery_location = eval(params[:delivery_location])

                if delivery_location.instance_of?(Hash)

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

                        if geo_location_country_code == product.store_country

                          # Store can be upto 100 KM from delivery location

                          store_location = store_user.store_address

                          distance = calculate_distance_km(delivery_location, store_location )


                          if distance <= 100

                            order_type = params[:order_type]

                            if is_order_type_valid?(order_type)

                              order_type = order_type.to_i


                              if order_type == 0 && distance > 25

                                # Standard delivery is only available if delivery location is within 25 KM of the store

                                @success = false
                                @error_code = 5
                                @product = product.to_json


                              else

                                # The stock quantity of the product will be decremented after an order is created

                                # If the order was till pending after 15 minutes the stock quantity of the product will be

                                # re-incremented and the order will be marked canceled



                                ordered_product = {
                                    id: product.id,
                                    quantity: quantity,
                                    price: product.price,
                                    currency: product.currency,
                                    product_options: product_options,
                                    name: product.name
                                }


                                order = Order.new

                                order.products = [ordered_product]
                                order.delivery_location = delivery_location
                                order.store_user_id = store_user.id
                                order.customer_user_id = customer_user.id
                                order.country = geo_location_country_code
                                order.order_type = order_type

                                if order.save!

                                  @success = true

                                  @order = {}

                                  @order[:id] = order.id

                                  @order[:products] = order.products

                                  @order[:created_at] = order.created_at

                                  @order[:updated_at] = order.updated_at

                                  @order[:order_type] = order.order_type



                                  stock_quantity = product.stock_quantity - quantity

                                  product.update!(stock_quantity: stock_quantity)


                                  Delayed::Job.enqueue(OrderJob.new(order.id), queue: 'order_check_queue', priority: 0, run_at: 15.minutes.from_now)



                                else


                                  @success = false

                                end





                              end


                            else

                              @success = false

                            end

                          else


                            @success = false
                            @error_code = 4
                            @product = product.to_json

                          end




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


  private


  def is_order_type_valid?(order_type)


    res = /^(?<num>\d+)$/.match(order_type)

    if res == nil

      false

    else

      order_type = order_type.to_i

      order_type == 0 || order_type == 1

    end


  end


  def calculate_distance_km(loc1, loc2)

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[:latitude]-loc1[:latitude]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[:longitude]-loc1[:longitude]) * rad_per_deg


    lat1_rad = loc1[:latitude] * rad_per_deg
    lat2_rad = loc2[:latitude] * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    (rm * c) / 1000.0 # Delta in KM

  end


  def is_number?(arg)

    arg.is_a?(Numeric)

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

        quantity <= product.stock_quantity

      end



    end

  end

end