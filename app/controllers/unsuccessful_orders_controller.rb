class UnsuccessfulOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include OrderHelper

  include ProductsHelper

  include PaymentsHelper

  include NotificationsHelper


  before_action :authenticate_admin!


  def cancel_order

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      order = Order.find_by(id: params[:order_id])

      if order != nil

        if is_order_unsuccessful?(order)

          @success = true

          driver = Driver.find_by(id: order.driver_id)

          store_user = StoreUser.find_by(id: order.store_user_id)


          order.canceled!

          order.update!(canceled_by: current_admin.full_name)


          refund_order(order)


          driver.permanently_blocked!


          driver_payment_intent =  Stripe::PaymentIntent.retrieve(order.driver_payment_intent)

          if driver_payment_intent.status == 'requires_capture'

            driver_payment_intent =  Stripe::PaymentIntent.capture(driver_payment_intent.id)

          end


          timezone = get_store_timezone_name(store_user)


          if driver_payment_intent.status == 'succeeded'

            balance_transaction = Stripe::BalanceTransaction.retrieve(driver_payment_intent.charges.data.first.balance_transaction)

            total_payment = driver_payment_intent.charges.data.first.amount_captured.to_f / 100.to_f

            fee_payment = balance_transaction.fee.to_f / 100.to_f


            net_store = total_payment - fee_payment

            net_store = convert_amount(net_store, 'USD', store_user.currency).round(2)

            total_payment_store_currency = convert_amount(total_payment, 'USD', store_user.currency).round(2)


            Payment.create!(
                amount: total_payment_store_currency,
                fee: total_payment_store_currency - net_store,
                net: net_store,
                currency: store_user.currency,
                store_user_id: store_user.id,
                timezone: timezone
            )


            store_user.increment!(:balance, net_store)


            store_user.send_notification(
                "#{net_store} #{store_user.currency} have been deposited to your balance",
                'Payment Received',
                {
                    show_orders: true
                }
            )


            send_driver_notification(
                order,
                "The order of the customer #{order.get_customer_name} ordered from #{order.get_store_name} was canceled, and a refund has been issued to the customer for their order. We kindly request that you return the order back to the store to be able to get the captured amount from your balance back from the store ( which is equivalent to the cost of the ordered product(s) ).",
                'Order Canceled'
            )


            send_store_notification(
                order,
                "The order of your customer #{order.get_customer_name} was canceled and a refund has been issued for the customer since the driver ( #{driver.name} ) failed to do the delivery. A payment was sent to the store balance for the cost of the ordered products(s) from the driver's balance. If the driver returns to your store back with the ordered product(s) you may choose to return the money back to the driver to get your product(s) back.",
                'Order Canceled',
                {
                    show_orders: true
                }
            )




          else

            order_total = order.total_price.to_f.round(2)

            delivery_fee = order.delivery_fee.to_f.round(2)

            products_price = order_total - delivery_fee

            products_price_driver_currency = convert_amount(products_price, 'USD', driver.currency).round(2)


            if driver.balance > 0


              driver_balance = driver.balance.to_f.round(2)


              if driver_balance <= products_price_driver_currency

                driver_decrement = driver_balance

              else

                driver_decrement = products_price_driver_currency

              end



              driver.decrement!(:balance, driver_decrement)


              store_increment = convert_amount(driver_decrement, driver.currency, store_user.currency).round(2)



              Payment.create!(
                  amount: store_increment,
                  fee: 0,
                  net: store_increment,
                  currency: store_user.currency,
                  store_user_id: store_user.id,
                  timezone: timezone
              )


              store_user.increment!(:balance, store_increment)




              store_user.send_notification(
                  "#{store_increment} #{store_user.currency} have been deposited to your balance",
                  'Payment Received',
                  {
                      show_orders: true
                  }
              )


              store_increment_usd = convert_amount(store_increment, store_user.currency, 'USD').round(2)


              if store_increment_usd == products_price

                # Full Recovery

                send_driver_notification(
                    order,
                    "The order of the customer #{order.get_customer_name} ordered from #{order.get_store_name} was canceled, and a refund has been issued to the customer for their order. We kindly request that you return the order back to the store to be able to get the captured amount from your balance back from the store ( which is equivalent to the cost of the ordered product(s) ).",
                    'Order Canceled'
                )


                send_store_notification(
                    order,
                    "The order of your customer #{order.get_customer_name} was canceled and a refund has been issued for the customer since the driver ( #{driver.name} ) failed to do the delivery. A payment was sent to the store balance for the cost of the ordered products(s) from the driver's balance. If the driver returns to your store back with the ordered product(s) you may choose to return the money back to the driver to get your product(s) back.",
                    'Order Canceled',
                    {
                        show_orders: true
                    }
                )


              else

                # Partial Recovery

                send_store_notification(
                    order,
                    "The order of your customer #{order.get_customer_name} was canceled and a refund has been issued for the customer since the driver ( #{driver.name} ) failed to do the delivery. We were able to recover #{store_increment} #{store_user.currency} from the driver's balance and sent them as a payment to your balance. You may consider reporting the driver to the local police to get your product(s) back, all of the driver's information is attached to the order in the order's page.",
                    'Order Canceled',
                    {
                        show_orders: true
                    }
                )



              end




              ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
                  driver_balance_usd: driver.get_balance_usd
              }


            else


              # No Recovery

              send_store_notification(
                  order,
                  "The order of your customer #{order.get_customer_name} was canceled and a refund has been issued for the customer since the driver ( #{driver.name} ) failed to do the delivery. You may consider reporting the driver to the local police to get your product(s) back, all of the driver's information is attached to the order in the order's page.",
                  'Order Canceled',
                  {
                      show_orders: true
                  }
              )


            end




          end


          send_customer_notification(
              order,
              "The order you made from #{order.get_store_name} has been canceled since the driver failed to do the delivery and a refund has been issued for your order.",
              'Order Canceled'
          )


          order.update!(order_canceled_reason: 'Driver did not fulfill order')


          send_store_orders(order)

          send_customer_orders(order)

          send_driver_orders(driver)



          ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
              unsuccessful_orders: driver.get_unsuccessful_orders,
              driver_account_status: driver.account_status
          }


          if !driver.has_unsuccessful_orders?

            ActionCable.server.broadcast 'unsuccessful_orders_channel', {
                delete_driver: true,
                driver_id: driver.id
            }

            ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
                current_resolvers: []
            }

            driver.update!(admins_resolving: [])

          end




        else

          @success = false

        end

      else

        @success = false

      end


    end


  end



  def confirm_order

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else


      order = Order.find_by(id: params[:order_id])

      if order != nil

        if is_order_unsuccessful?(order)

          @success = true

          driver = Driver.find_by(id: order.driver_id)


          order.complete!

          order.update!(driver_fulfilled_order: true, confirmed_by: current_admin.full_name)

          driver.remove_temporary_block


          order.release_driver_funds

          increment_store_balance(order)

          increment_driver_balance(order, driver)


          send_store_orders(order)

          send_customer_orders(order)

          send_driver_orders(driver)

          notify_unavailable_products(order)


          ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
              unsuccessful_orders: driver.get_unsuccessful_orders,
              driver_account_status: driver.account_status
          }


          if !driver.has_unsuccessful_orders?

            ActionCable.server.broadcast 'unsuccessful_orders_channel', {
                delete_driver: true,
                driver_id: driver.id
            }

            ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
                current_resolvers: []
            }

            driver.update!(admins_resolving: [])

          end





        else

          @success = false

        end


      else

        @success = false

      end



    end



  end


  def show

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      driver = Driver.find_by(id: params[:driver_id])

      if driver != nil

        unsuccessful_orders = driver.get_unsuccessful_orders

        if unsuccessful_orders.size == 0

          @success = false

        else

          @success = true

          @unsuccessful_orders = unsuccessful_orders

          @driver_name = driver.name

          @driver_phone_number = driver.get_phone_number

          @driver_country = driver.get_country_name

          @driver_account_status = driver.account_status

          @driver_balance_usd = driver.get_balance_usd

          @driver_latitude = driver.latitude

          @driver_longitude = driver.longitude

        end


      else

        @success = false

      end


    end


  end


  def search_drivers

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized


    else

      # search for drivers with unsuccessful orders by name

      # filter orders by country

      @drivers = []

      search = params[:search]

      country = params[:country]

      if search != nil

        search = search.strip

        drivers = get_drivers

        drivers = drivers.where("name ILIKE ?", "%#{search}%")


        if !country.blank?

          drivers = drivers.where(country: country)

        end



        drivers.each do |driver|

          next_order_resolve_time_limit = driver.next_order_resolve_time_limit

          if !next_order_resolve_time_limit.nil?

            @drivers.push(get_driver_item(driver, next_order_resolve_time_limit))

          end

        end


        @drivers = @drivers.sort_by { |hsh| hsh[:next_order_resolve_time_limit] }


      end


    end


  end


  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized


    else

      @drivers = []

      drivers = get_drivers


      drivers.each do |driver|

        next_order_resolve_time_limit = driver.next_order_resolve_time_limit

        if !next_order_resolve_time_limit.nil?

          @drivers.push(get_driver_item(driver, next_order_resolve_time_limit))

        end

      end

      @drivers = @drivers.sort_by { |hsh| hsh[:next_order_resolve_time_limit] }



      @countries = get_countries



    end

  end


  private


  def get_driver_item(driver, next_order_resolve_time_limit)

    {
        id: driver.id,
        name: driver.name,
        country: driver.get_country_name,
        next_order_resolve_time_limit: next_order_resolve_time_limit
    }


  end


  def is_order_unsuccessful?(order)

    order.ongoing? &&
        order.store_accepted? &&
        !order.store_handles_delivery &&
        order.store_fulfilled_order &&
        !order.driver_fulfilled_order &&
        ( order.delivery_time_limit <= DateTime.now.utc )

  end

  def get_drivers

    # Get all drivers with unsuccessful orders

    driver_ids = Order.all.where(
        status: 2,
        store_confirmation_status: 2,
        store_handles_delivery: false,
        store_fulfilled_order: true,
        driver_fulfilled_order: false
    ).where('delivery_time_limit <= ?', DateTime.now.utc).distinct.pluck(:driver_id)

    Driver.where(id: driver_ids)


  end




end
