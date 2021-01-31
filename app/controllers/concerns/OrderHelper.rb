module OrderHelper

  include MoneyHelper

  include PaymentsHelper

  include NotificationsHelper

  require 'faraday'
  require 'faraday_middleware'
  require 'net/http'

  def send_store_orders(order)

    store_user = StoreUser.find_by(id: order.store_user_id)

    orders = get_store_orders(store_user)

    store = store_user.store

    ActionCable.server.broadcast "store_orders_channel_#{store.id}", {orders: orders}

    store_user.employees.each do |employee|

      if employee.has_roles?(:order_manager)

        ActionCable.server.broadcast "employee_orders_channel_#{employee.id}", {orders: orders}

      end

    end


  end


  def send_customer_orders(order)

    customer_user = CustomerUser.find_by(id: order.customer_user_id)

    orders = get_customer_orders(customer_user)

    customer = customer_user.customer

    ActionCable.server.broadcast "customer_orders_channel_#{customer.id}", {orders: orders}

  end


  def send_driver_orders(driver)

    orders = get_driver_orders(driver)

    driver_customer_user = driver.customer_user

    ActionCable.server.broadcast "driver_channel_#{driver_customer_user.id}", {
        orders: orders
    }


  end


  def get_new_driver(order)

    previous_driver_id = order.driver_id

    store_user = StoreUser.find_by(id: order.store_user_id)

    order.pending!

    order.update!(
        driver_arrived_to_store: false,
        driver_id: nil,
        prospective_driver_id: nil,
        drivers_rejected: [],
        store_arrival_time_limit: nil,
        driver_fulfilled_order_code: SecureRandom.hex
    )

    drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

    drivers_canceled_order.push(previous_driver_id)

    order.update!(drivers_canceled_order: drivers_canceled_order)

    send_store_orders(order)

    send_customer_orders(order)

    previous_driver = Driver.find_by(id: previous_driver_id)

    send_driver_orders(previous_driver)

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

  def is_decimal_number?(arg)

    arg = arg.to_s

    /^-?(\d+\.?\d*|\d*\.?\d+)$/.match(arg) != nil

  end


  def increment_driver_balance(order, driver)

    store_user = StoreUser.find_by(id: order.store_user_id)

    timezone = get_store_timezone_name(store_user)


    payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

    balance_transaction = Stripe::BalanceTransaction.retrieve(payment_intent.charges.data.first.balance_transaction)


    total_payment = balance_transaction.amount.to_f / 100.to_f

    fee_payment = balance_transaction.fee.to_f / 100.to_f


    order_total = order.total_price.to_f.round(2)

    order_fee = ( order_total / total_payment  ) * fee_payment

    order_net = order_total - order_fee


    delivery_fee = order.delivery_fee.to_f.round(2)

    net_driver = ( delivery_fee / order_total ) * order_net



    our_earning = net_driver * 0.1

    our_earning = our_earning.round(2)

    Earning.create!(amount: our_earning)


    net_driver = net_driver - our_earning

    net_driver = convert_amount(net_driver, 'USD', driver.currency).round(2)

    driver.increment!(:balance, net_driver)


    delivery_fee_driver_currency = convert_amount(delivery_fee, 'USD', driver.currency).round(2)

    Payment.create!(
        amount: delivery_fee_driver_currency,
        fee: delivery_fee_driver_currency - net_driver,
        net: net_driver,
        currency: driver.currency,
        driver_id: driver.id,
        timezone: timezone
    )



    driver.send_notification(
        "#{net_driver} #{driver.currency} have been deposited to your balance",
        'Payment Received',
        {
            show_driver_orders: true
        }
    )


  end




  def increment_store_balance(order)

    store_user = StoreUser.find_by(id: order.store_user_id)

    store_handles_delivery = order.store_handles_delivery

    timezone = get_store_timezone_name(store_user)


    payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

    balance_transaction = Stripe::BalanceTransaction.retrieve(payment_intent.charges.data.first.balance_transaction)


    total_payment = balance_transaction.amount.to_f / 100.to_f

    fee_payment = balance_transaction.fee.to_f / 100.to_f


    order_total = order.total_price.to_f.round(2)

    order_fee = ( order_total / total_payment  ) * fee_payment

    order_net = order_total - order_fee


    if store_handles_delivery

      our_earning = order_net * 0.1

      our_earning = our_earning.round(2)

      Earning.create!(amount: our_earning)


      net_store = order_net - our_earning


      net_store = convert_amount(net_store, 'USD', store_user.currency).round(2)

      order_total_store_currency = convert_amount(order_total, 'USD', store_user.currency).round(2)


      Payment.create!(
          amount: order_total_store_currency,
          fee: order_total_store_currency - net_store,
          net: net_store,
          currency: store_user.currency,
          store_user_id: store_user.id,
          timezone: timezone
      )


    else

      delivery_fee = order.delivery_fee.to_f.round(2)

      products_price = order_total - delivery_fee

      net_store = ( products_price / order_total ) * order_net


      our_earning = net_store *  0.1

      our_earning = our_earning.round(2)

      Earning.create!(amount: our_earning)



      net_store = net_store - our_earning


      net_store = convert_amount(net_store, 'USD', store_user.currency).round(2)

      order_total_store_currency = convert_amount(order_total, 'USD', store_user.currency).round(2)


      Payment.create!(
          amount: order_total_store_currency,
          fee: order_total_store_currency - net_store,
          net: net_store,
          currency: store_user.currency,
          store_user_id: store_user.id,
          timezone: timezone
      )



    end


    store_user.increment!(:balance, net_store)


    store_user.send_notification(
        "#{net_store} #{store_user.currency} have been deposited to your balance",
        'Payment Received',
        {
            show_orders: true
        }
    )


  end

  def find_next_element_index(element, array)
    index = array.find_index(element) + 1
    index % array.size
  end


  def can_contact_driver?(driver_id)

    # Driver can only be contacted with a new order request if he has no other pending order request

    Order.all.where(driver_id: nil, status: 1, prospective_driver_id: driver_id).length == 0

  end


  def contact_drivers(drivers, order, store_user)

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    puts  "Drivers Rejected #{drivers_rejected}"

    if drivers.length > 0

      # Find the nearest available driver to the store and contact him

      driver_found = false

      drivers.each do |driver|

        if can_contact_driver?(driver.id)

          payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

          if payment_intent.status == 'canceled'

            # If payment_intent is canceled then cancel the order and dont contact the new driver

            # This is an optimization and this is already being handled when driver accepts order request as well

            order.canceled!

            order.update!(order_canceled_reason: 'Order has expired')

            send_store_orders(order)

            send_customer_orders(order)

            send_customer_notification(
                order,
                "Your order from #{order.get_store_name} has expired and a refund has been issued for your order",
                'Order has expired',
                {
                    show_orders: true
                }
            )

            OrderMailer.delay.order_expired(order.get_customer_email, order.get_store_name)

          else

            order.update!(prospective_driver_id: driver.id)

            puts "Contacting new driver #{driver.name} with ID #{driver.id}"

            delivery_fee = convert_amount(order.delivery_fee, order.delivery_fee_currency, driver.currency)

            order_type = order.order_type

            ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                contacting_driver: true,
                order_id: order.id,
                store_latitude: store_user.store_address[:latitude],
                store_longitude: store_user.store_address[:longitude],
                delivery_location_latitude: order.delivery_location[:latitude],
                delivery_location_longitude: order.delivery_location[:longitude],
                store_name: store_user.store_name,
                delivery_fee: delivery_fee,
                order_type: order_type,
                currency: driver.currency
            }

            Delayed::Job.enqueue(
                OrderJob.new(order.id, driver.id),
                queue: 'order_job_queue',
                priority: 0,
                run_at: 30.seconds.from_now
            )

            driver_found = true


          end


          break


        end

      end


      if !driver_found

        no_drivers_found(order, store_user)

      end


    else

      no_drivers_found(order, store_user)

    end


  end



  def other_standard_delivery_drivers(order, store_latitude, store_longitude, store_user)

    # Fetch all online drivers that between 25KM and 50KM away from the store

    # That  dont have any ongoing orders and dont have any orders

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

    invalid_drivers = drivers_rejected + drivers_canceled_order

    country = store_user.store_country

    drivers = Driver.in_range(25..50, :origin => [store_latitude, store_longitude]).where(status: 1, country: country, account_status: 0).where.not(id: invalid_drivers)

    drivers = drivers.includes(:orders).where(orders: { driver_id: nil }) + drivers.includes(:orders).where.not(orders: {status: 2})

    drivers = drivers.uniq

    drivers.sort_by{|driver| driver.distance_to([store_latitude, store_longitude])}

    drivers


  end

  def contact_standard_drivers(drivers,  order, store_user, store_latitude, store_longitude)


    if drivers.length > 0

      contact_drivers(drivers, order, store_user)

    else

      drivers = other_standard_delivery_drivers(order, store_latitude, store_longitude, store_user)

      if drivers.length > 0

        contact_drivers(drivers,  order, store_user)

      else

        no_drivers_found(order, store_user)

      end

    end



  end


  def drivers_standard_delivery(order, store_user, store_latitude, store_longitude)

    store_location = store_user.store_address

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

    invalid_drivers = drivers_rejected + drivers_canceled_order

    # Fetch all drivers that are within 25 KM away from the store

    country = store_user.store_country

    drivers = Driver.within(25, :origin=> [store_latitude, store_longitude]).where(status: 1, country: country, account_status: 0).where.not(id: invalid_drivers)

    # Fetch all online drivers who have no orders and dont have any exclusive orders ongoing

    drivers = drivers.includes(:orders).where(orders: { driver_id: nil }) + drivers.includes(:orders).where.not(orders: {status: 2, order_type: 1})

    drivers = drivers.uniq

    drivers = drivers.select do |driver|

      # The driver might have other standard orders ongoing or he might not have any orders ongoing at all

      standard_orders = driver.orders.where(status: 2, order_type: 0).order(created_at: :asc)

      if standard_orders.length == 0

        true

      else

        # Driver can accept other standard orders if he has picked up all products

        # For the current ongoing standard orders he might have

        unpicked_orders = driver.orders.where(status: 2, order_type: 0, store_fulfilled_order: false)

        if unpicked_orders.length > 0

          false

        else

          # The driver can only accept standard orders from other customers whose delivery location are within

          # 25 KM away from the store location of the first order and whose store location is within 25 KM away

          # from the delivery location of the first order

          first_order = standard_orders.first

          first_order_store_location = StoreUser.find_by(id: first_order.store_user_id).store_address

          first_order_delivery_location = first_order.delivery_location

          delivery_location = order.delivery_location

          # First order store location distance to the new order delivery location

          d1 = calculate_distance_km(first_order_store_location, delivery_location)

          # New order store location distance to the delivery location of first order

          d2 = calculate_distance_km(store_location, first_order_delivery_location)

          d1 <= 25 && d2 <= 25


        end






      end



    end


    drivers = drivers.sort_by{|driver| driver.distance_to([store_latitude, store_longitude])}


    contact_standard_drivers(drivers, order, store_user, store_latitude, store_longitude)


  end

  def drivers_exclusive_delivery(order, store_user, store_latitude, store_longitude)

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

    invalid_drivers = drivers_rejected + drivers_canceled_order

    # Driver can be within a 50KM radius maximum

    country = store_user.store_country

    drivers = Driver.within(50, :origin=> [store_latitude, store_longitude]).where(status: 1, country: country, account_status: 0).where.not(id: invalid_drivers)

    # Fetch all online drivers who have no orders and who have no ongoing orders

    drivers = drivers.includes(:orders).where(orders: { driver_id: nil }) + drivers.includes(:orders).where.not(orders: {status: 2})

    drivers = drivers.uniq

    drivers = drivers.sort_by{|driver| driver.distance_to([store_latitude, store_longitude])}

    contact_drivers(drivers, order, store_user)

  end

  def drivers_has_sensitive_products(order, store_user, store_latitude, store_longitude)

    # Driver can be within a 7KM radius maximum

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    drivers_canceled_order = order.drivers_canceled_order.map(&:to_i)

    invalid_drivers = drivers_rejected + drivers_canceled_order

    country = store_user.store_country

    drivers = Driver.within(7, :origin=> [store_latitude, store_longitude]).where(status: 1, country: country, account_status: 0).where.not(id: invalid_drivers)

    # Fetch all online drivers who have no orders and who have no ongoing orders

    drivers = drivers.includes(:orders).where(orders: { driver_id: nil }) + drivers.includes(:orders).where.not(orders: {status: 2})

    drivers = drivers.uniq

    drivers = drivers.sort_by{|driver| driver.distance_to([store_latitude, store_longitude])}

    contact_drivers(drivers, order, store_user)


  end


  def no_drivers_found(order, store_user)


    # If no driver was found within valid area cancel the order and notify store/employee/customer

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

    send_store_orders(order)

    send_customer_orders(order)


    payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

    if payment_intent.status == 'requires_capture'

      cancel_payment_intent(order)

    else

      refund_order(order)

    end


    send_store_notification(
        order,
        "No drivers were found and a refund has been be issued for your customer #{order.get_customer_name}",
        'Order was canceled',
        {
            show_orders: true
        }
    )


    send_customer_notification(
        order,
        'No drivers were found and a refund has been issued for your order',
        'Your order was canceled',
        {
            show_orders: true
        }
    )


    OrderMailer.delay.no_drivers(order.get_customer_email, order.get_store_name)


  end


  def get_store_timezone_name(store_user)

    store_address = store_user.store_address

    store_latitude = store_address[:latitude]

    store_longitude = store_address[:longitude]

    Rails.cache.fetch("(store_user_#{store_user.id}).timezone_name", expires_in: 0) do

      timezone = Timezone.lookup(store_latitude, store_longitude)

      timezone.name

    end

  end

  def location_timezone_name(latitude, longitude)

    Rails.cache.fetch("(#{latitude},#{longitude}).timezone_name", expires_in: 0) do

      timezone = Timezone.lookup(latitude, longitude)

      timezone.name

    end

  end



  def get_store_order(store_order, store_user)

    order = {}

    timezone = get_store_timezone_name(store_user)

    order[:created_at] = store_order.created_at

    order[:ordered_at] = store_order.created_at.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d %-I:%M %p')

    store_handles_delivery = store_order.store_handles_delivery

    order[:store_handles_delivery] = store_handles_delivery

    if store_handles_delivery

      delivery_time_limit = store_order.delivery_time_limit

      if delivery_time_limit != nil

        order[:delivery_time_limit] = delivery_time_limit.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d %-I:%M %p')

      end

      order[:tracking_website_url] = store_order.tracking_website_url

      order[:tracking_number] = store_order.tracking_number

      order[:receipt_url] = store_order.receipt.url


    else

      order[:driver_arrived_to_delivery_location] = store_order.driver_arrived_to_delivery_location

      order[:driver_arrived_to_store] = store_order.driver_arrived_to_store

      order[:driver_fulfilled_order] = store_order.driver_fulfilled_order

      order[:store_fulfilled_order] = store_order.store_fulfilled_order

      if store_order.driver_id != nil

        driver = Driver.find_by(id: store_order.driver_id)

        driver_information = {}

        driver_information[:name] = driver.name

        driver_information[:profile_picture] = driver.profile_picture.url

        driver_license_pictures = []

        national_id_pictures = []

        vehicle_registration_pictures = []

        driver.driver_license_pictures.each do |picture|

          driver_license_pictures.push(picture.url)

        end

        driver.national_id_pictures.each do |picture|

          national_id_pictures.push(picture.url)


        end


        driver.vehicle_registration_document_pictures.each do |picture|


          vehicle_registration_pictures.push(picture.url)

        end

        driver_information[:license_pictures] = driver_license_pictures

        driver_information[:national_id_pictures] = national_id_pictures

        driver_information[:vehicle_registration_pictures] = vehicle_registration_pictures

        order[:driver] = driver_information


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
        phone_number: customer_user.phone_number,
        building_name: customer_user.building_name,
        apartment_floor: customer_user.apartment_floor
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

    order


  end


  def convert_amount(amount, from_currency, to_currency)


    if from_currency == to_currency

      amount

    else

      exchange_rates = get_exchange_rates(to_currency)

      amount / exchange_rates[from_currency]


    end


  end


  def get_customer_orders(customer_user)

    orders = []

    customer_user.orders.order(created_at: :desc).each do |customer_order|

      order = {}

      store = {}

      store_user = StoreUser.find_by(id: customer_order.store_user_id)

      store[:name] = store_user.store_name

      store[:logo] = store_user.store.profile.profile_picture.url

      order[:store] = store

      default_currency = customer_user.default_currency

      order[:currency] = default_currency

      delivery_location = customer_order.delivery_location

      latitude = delivery_location[:latitude]

      longitude = delivery_location[:longitude]

      timezone = location_timezone_name(latitude, longitude)

      order[:created_at] = customer_order.created_at

      order[:ordered_at] = customer_order.created_at.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d %-I:%M %p')

      store_handles_delivery = customer_order.store_handles_delivery

      order[:store_handles_delivery] = store_handles_delivery


      if store_handles_delivery

        delivery_time_limit = customer_order.delivery_time_limit

        if delivery_time_limit != nil

          order[:delivery_time_limit] = delivery_time_limit.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d %-I:%M %p')

        end

        order[:tracking_website_url] = customer_order.tracking_website_url

        order[:tracking_number] = customer_order.tracking_number


      else

        order[:driver_fulfilled_order] = customer_order.driver_fulfilled_order

        order[:store_fulfilled_order] = customer_order.store_fulfilled_order

        if customer_order.driver_id != nil

          driver = Driver.find_by(id: customer_order.driver_id)

          order[:driver_name] = driver.name

        end



        delivery_fee = customer_order.delivery_fee

        delivery_fee_currency = customer_order.delivery_fee_currency

        delivery_fee = convert_amount(delivery_fee, delivery_fee_currency, default_currency)

        order[:delivery_fee] = delivery_fee


      end

      order_canceled_reason = customer_order.order_canceled_reason

      if order_canceled_reason.length > 0

        order[:order_canceled_reason] = order_canceled_reason

      end


      if customer_order.store_unconfirmed?

        order[:store_confirmation_status_label] = 'Unconfirmed'

      elsif customer_order.store_rejected?

        order[:store_confirmation_status_label] = 'Rejected'

      elsif customer_order.store_accepted?

        order[:store_confirmation_status_label] = 'Accepted'

      end


      order[:store_confirmation_status] = customer_order.store_confirmation_status

      order_type = customer_order.order_type

      if order_type != nil

        order[:order_type] = customer_order.order_type

      end


      order[:status] = customer_order.status

      products = []

      customer_order.products.each do |ordered_product|

        ordered_product = eval(ordered_product)

        product = Product.find_by(id: ordered_product[:id])


        product_price = ordered_product[:price]

        product_currency = ordered_product[:currency]


        product_price = convert_amount(product_price, product_currency, default_currency)

        products.push({
                          id: ordered_product[:id],
                          quantity: ordered_product[:quantity],
                          price: product_price,
                          currency: default_currency,
                          product_options: ordered_product[:product_options],
                          name: product.name,
                          picture: product.main_picture.url
                      })


      end

      order[:products] = products

      order[:id] = customer_order.id

      total_price = customer_order.total_price

      total_price_currency = customer_order.total_price_currency

      total_price = convert_amount(total_price, total_price_currency, default_currency)

      order[:total_price] = total_price


      orders.push(order)


    end

    orders

  end

  def get_store_orders(store_user)

    orders = []

    store_user.orders.order(created_at: :desc).each do |store_order|

      order = get_store_order(store_order, store_user)

      orders.push(order)

    end

    orders

  end


  def get_driver_order(driver, order)

    driver_order = {}

    # Order Location Information

    ## Customer location

    delivery_location_latitude = order.delivery_location[:latitude]

    delivery_location_longitude = order.delivery_location[:longitude]

    customer_location = {}

    customer_location[:latitude] = delivery_location_latitude

    customer_location[:longitude] = delivery_location_longitude

    driver_order[:customer_location] = customer_location


    ## Store Location

    store_user = StoreUser.find_by(id: order.store_user_id)

    store_location = {}

    store_latitude = store_user.store_address[:latitude]

    store_longitude = store_user.store_address[:longitude]

    store_location[:latitude] = store_latitude

    store_location[:longitude] = store_longitude

    driver_order[:store_location] = store_location


    # Order General Information

    driver_order[:id] = order.id

    driver_order[:status] = order.status

    timezone = location_timezone_name(delivery_location_latitude, delivery_location_longitude)

    driver_order[:created_at] = order.created_at

    driver_order[:ordered_at] = order.created_at.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d %-I:%M %p')

    delivery_fee = convert_amount(order.delivery_fee.to_f.round(2), order.delivery_fee_currency, driver.currency)

    driver_order[:delivery_fee] = delivery_fee

    driver_order[:delivery_fee_currency] = driver.currency

    driver_order[:order_type] = order.order_type

    order_canceled_reason = order.order_canceled_reason

    if order_canceled_reason.length > 0

      driver_order[:order_canceled_reason] = order_canceled_reason

    end

    driver_order[:driver_received_order_code] = order.driver_received_order_code

    driver_order[:driver_fulfilled_order_code] = order.driver_fulfilled_order_code

    driver_order[:store_fulfilled_order] = order.store_fulfilled_order

    driver_order[:driver_fulfilled_order] = order.driver_fulfilled_order

    delivery_time_limit = order.delivery_time_limit

    if delivery_time_limit != nil

      delivery_time_limit = delivery_time_limit.to_datetime

      elapsed_seconds = ((delivery_time_limit - (DateTime.now.utc).to_datetime) * 24 * 60 * 60).to_i

      if elapsed_seconds < 0

        driver_order[:delivery_time_left] = 0

      else

        driver_order[:delivery_time_left] = elapsed_seconds

      end

    end


    store_arrival_time_limit = order.store_arrival_time_limit

    if store_arrival_time_limit != nil

      store_arrival_time_limit = store_arrival_time_limit.to_datetime

      elapsed_seconds = ((store_arrival_time_limit - (DateTime.now.utc).to_datetime) * 24 * 60 * 60).to_i

      if elapsed_seconds < 0

        driver_order[:store_arrival_time_left] = 0

      else

        driver_order[:store_arrival_time_left] = elapsed_seconds

      end


    end



    # Store Information

    store = {}

    store[:name] = store_user.store_name

    store[:number] = store_user.store_number

    driver_order[:store] = store


    # Customer Information

    customer_user = CustomerUser.find_by(id: order.customer_user_id)

    customer = {}

    customer[:name] = customer_user.full_name

    customer[:number] = customer_user.phone_number

    customer[:building_name] = customer_user.building_name

    customer[:apartment_floor] = customer_user.apartment_floor

    driver_order[:customer] = customer


    driver_order



  end


  def get_driver_orders(driver)

    driver_orders = []

    driver.orders.order(created_at: :desc).each do |order|

      driver_order = get_driver_order(driver, order)

      driver_orders.push(driver_order)

    end

    driver_orders

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

  def estimated_arrival_time_minutes(origin_lat, origin_lng, dest_lat, dest_lng)

    url = 'https://maps.googleapis.com/maps/api/distancematrix'

    conn = Faraday.new(url: url) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get(
        'json',
        units: 'metric',
        origins: "#{origin_lat},#{origin_lng}",
        destinations: "#{dest_lat},#{dest_lng}",
        key: ENV.fetch('GOOGLE_API_KEY')
    )

    data = response.body['rows'][0]['elements'][0]


    data['duration']['value'] / 60 # Minutes


  end

  def calculate_distance_meters(loc1, loc2)

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[:latitude]-loc1[:latitude]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[:longitude]-loc1[:longitude]) * rad_per_deg


    lat1_rad = loc1[:latitude] * rad_per_deg
    lat2_rad = loc2[:latitude] * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c # Delta in Meters

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


    order_type = order_type.to_s

    res = /^(?<num>\d+)$/.match(order_type)

    if res == nil

      false

    else

      order_type = order_type.to_i

      order_type == 0 || order_type == 1

    end


  end


  def does_not_handle_delivery_order(order_type, store_schedule, store_user)

    timezone = get_store_timezone_name(store_user)

    local_time = Time.now.to_datetime.in_time_zone(timezone)

    if order_type == 0


      # Order is created and remains pending until the store accepts or rejects the order the next day even if store closed

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


        can_order_1 || can_order_2



      end


    end



  end


  def handles_delivery_order(has_sensitive_products, store_schedule, store_user)

    timezone = get_store_timezone_name(store_user)

    local_time = Time.now.to_datetime.in_time_zone(timezone)

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


        can_order_1 || can_order_2



      end


    else

      # Order is created and remains pending until the store accepts or rejects the order the next day even if store closed

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




end