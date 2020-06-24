module OrderHelper

  require 'faraday'
  require 'faraday_middleware'
  require 'net/http'


  def find_next_element_index(element, array)
    index = array.find_index(element) + 1
    index % array.size
  end


  def drivers_has_sensitive_products(order, store_user, store_latitude, store_longitude)

    # Driver can be within a 7KM radius maximum

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    unconfirmed_drivers = order.unconfirmed_drivers.map(&:to_i)

    puts "unconfirmed drivers #{unconfirmed_drivers}"

    drivers = Driver.within(7, :origin=> [store_latitude, store_longitude]).where(status: 1).where.not(id: drivers_rejected)

    # To be able to accept this order, driver cannot have any ongoing orders

    # Fetch all online drivers who have no orders and who have no ongoing orders

    drivers = drivers.includes(:orders).where(orders: { driver_id: nil }) + drivers.includes(:orders).where.not(orders: {status: 2})

    drivers = drivers.uniq

    drivers = drivers.sort_by{|driver| driver.distance_to([store_latitude, store_longitude])}


    if drivers.length > 0

      # Find the nearest driver to the store and contact him

      driver = drivers.select {|d| !unconfirmed_drivers.include?(d.id)}.first

      if driver != nil

        order.update!(prospective_driver_id: driver.id)

        puts "Contacting new driver #{driver.name} with ID #{driver.id}"

        # Create Delayed Job

        Delayed::Job.enqueue(
            OrderJob.new(order.id, driver.id),
            queue: 'order_job_queue',
            priority: 0,
            run_at: 30.seconds.from_now
        )


      else

        # Recontacts unconfirmed drivers who are still within valid area

        drivers = drivers.select {|d| unconfirmed_drivers.include?(d.id)}

        driver = drivers[find_next_element_index(order.prospective_driver_id, unconfirmed_drivers)]

        order.update!(prospective_driver_id: driver.id)

        puts "Contacting unconfirmed driver #{driver.name} with ID #{driver.id}"

        Delayed::Job.enqueue(
            OrderJob.new(order.id, driver.id),
            queue: 'order_job_queue',
            priority: 0,
            run_at: 30.seconds.from_now
        )



      end


      # The driver will have 30 seconds to accept or reject order

      # If the driver has accepted the order it will be as marked ongoing

      # If the driver rejected the order he will be added to the drivers rejected list and the second nearest

      # driver will be contacted ( 7KM max distance from store who have sensitive products and 50KM for others ).

      # If the driver let the order pass he will be added to unconfirmed drivers list

    else

      no_drivers_found(order, store_user)

    end

  end


  def no_drivers_found(order, store_user)


    # If no driver was found within valid area cancel the order and notify store/customer

    order.canceled!

    # Re-increment stock quantity of each product if applicable

    order.products.each do |ordered_product|

      ordered_product = eval(ordered_product)

      product = Product.find_by(id: ordered_product[:id])

      if (product != nil) && (product.stock_quantity != nil)

        stock_quantity = product.stock_quantity + ordered_product[:quantity]

        product.update!(stock_quantity: stock_quantity)

      end

    end

    order.update!(order_canceled_reason: 'No drivers found')

    orders = get_store_orders(store_user)

    # Send orders to customer_user and store_user channels

    ActionCable.server.broadcast "orders_channel_#{order.store_user_id}", {orders: orders}

    ActionCable.server.broadcast "orders_channel_#{order.customer_user_id}", {orders: orders}

    # Refund customer the amount he paid




  end

  def get_store_orders(store_user)


    orders = []

    store_address = store_user.store_address

    store_latitude = store_address[:latitude]

    store_longitude = store_address[:longitude]


    store_user.orders.order(created_at: :desc).each do |store_order|

      order = {}

      timezone = Timezone.lookup(store_latitude, store_longitude)

      order[:created_at] = store_order.created_at

      order[:ordered_at] = timezone.time_with_offset(store_order.created_at).strftime('%Y-%m-%d %-I:%M %p')


      driver_canceled_order = store_order.driver_canceled_order

      if driver_canceled_order != nil

        order[:driver_canceled_order] = driver_canceled_order

      end

      store_handles_delivery = store_order.store_handles_delivery

      order[:store_handles_delivery] = store_handles_delivery

      if store_handles_delivery

        delivery_time_limit = store_order.delivery_time_limit

        if delivery_time_limit != nil

          order[:delivery_time_limit] = timezone.time_with_offset(delivery_time_limit).strftime('%Y-%m-%d %-I:%M %p')

        end

      else

        order[:driver_arrived_to_delivery_location] = store_order.driver_arrived_to_delivery_location

        order[:driver_arrived_to_store] = store_order.driver_arrived_to_store

        order[:driver_fulfilled_order] = store_order.driver_fulfilled_order

        order[:store_fulfilled_order] = store_order.store_fulfilled_order

        if store_order.driver_id != nil

          driver = Driver.find_by(id: store_order.driver_id)

          order[:driver_name] = driver.name

        end

      end

      order_canceled_reason = store_order.order_canceled_reason

      if order_canceled_reason.length > 0

        order[:order_canceled_reason] = order_canceled_reason

      end

      customer_canceled_order = store_order.customer_canceled_order

      if customer_canceled_order

        order[:customer_canceled_order] = customer_canceled_order

      end


      order[:store_confirmation_status] = store_order.store_confirmation_status

      order_type = store_order.order_type

      if order_type != nil

        order[:order_type] = store_order.order_type

      end


      customer_user = CustomerUser.find_by(id: store_order.customer_user_id)

      customer = {
          name: customer_user.full_name,
          phone_number: customer_user.phone_number
      }

      order[:customer] = customer

      order[:delivery_location] = store_order.delivery_location

      order[:status] = store_order.status

      products = []


      store_order.products.each do |ordered_product|

        ordered_product = eval(ordered_product)


        product = Product.find_by(id: ordered_product[:id])

        products.push({
                          id: ordered_product[:id],
                          quantity: ordered_product[:quantity],
                          price: ordered_product[:price],
                          currency: ordered_product[:currency],
                          product_options: ordered_product[:product_options],
                          name: product.name,
                          picture: product.main_picture.url
                      })



      end

      order[:products] = products

      order[:id] = store_order.id

      orders.push(order)

    end

    orders

  end


  def calculate_standard_delivery_fee_usd(distance)


    # Distance represent the distance radius from store to delivery location

    if distance >= 0 && distance <= 1
      1.99
    elsif distance > 1 && distance <= 5
      2.99
    elsif distance > 5 && distance <= 10
      5.99
    elsif distance > 10 && distance <= 15
      7.99
    elsif distance > 15 && distance <= 25
      9.99
    end

  end


  def calculate_exclusive_delivery_fee_usd(delivery_location, store_location)

    # Returns delivery fee from store to delivery location in USD

    latitude = delivery_location[:latitude]

    longitude = delivery_location[:longitude]

    store_latitude = store_location[:latitude]

    store_longitude = store_location[:longitude]

    url = 'https://maps.googleapis.com/maps/api/distancematrix'

    conn = Faraday.new(url: url) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end

    response = Rails.cache.fetch("#{store_latitude},#{store_longitude}|#{latitude},#{longitude}", expires_in: 30.minutes) do
      conn.get(
          'json',
          units: 'metric',
          origins: "#{store_latitude},#{store_longitude}",
          destinations: "#{latitude},#{longitude}",
          key: ENV.fetch('GOOGLE_API_KEY')
      )
    end

    data = response.body['rows'][0]['elements'][0]

    travel_distance = data['distance']['value'] / 1000 # KM

    travel_time = data['duration']['value'] / 60 # Minutes

    0.0189 * travel_time + 0.533 * travel_distance + 2 # in USD

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

  def is_order_type_valid?(order_type)


    res = /^(?<num>\d+)$/.match(order_type)

    if res == nil

      false

    else

      order_type = order_type.to_i

      order_type == 0 || order_type == 1

    end


  end

end