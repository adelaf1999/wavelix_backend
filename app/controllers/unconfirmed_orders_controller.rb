class UnconfirmedOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include ValidationsHelper

  include UnconfirmedOrdersHelper

  include OrderHelper

  include ProductsHelper

  include PaymentsHelper

  include NotificationsHelper

  before_action :authenticate_admin!


  def cancel

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      order = Order.find_by(id: params[:order_id])

      if order != nil

        if is_order_unconfirmed?(order)

          @success = true

          order.canceled!

          refund_order(order)

          order.update!(
              admins_reviewing: [],
              refunded_by: current_admin.full_name
          )

          ActionCable.server.broadcast 'unconfirmed_orders_channel', {
              order_canceled: true,
              order_id: order.id
          }

          ActionCable.server.broadcast "view_unconfirmed_order_channel_#{order.id}", {
              order_canceled: true
          }


          store_name = order.get_store_name

          UnconfirmedOrderMailer.delay.notify_customer_order_canceled(order.get_customer_email, order.get_customer_name, store_name)

          send_customer_notification(
              order,
              "The order you made from #{store_name} was canceled since the store did not deliver the order to the delivery location and a refund has been issued for your order.",
              'Order Canceled',
              {
                  show_orders: true
              }
          )

          customer_name = order.get_customer_name

          UnconfirmedOrderMailer.delay.notify_store_order_canceled(order.get_store_email, customer_name)

          send_store_notification(
              order,
              "The order of your customer #{customer_name} was canceled because your customer did not receive the order they made and a refund has been issued for your customer.",
              'Order Canceled',
              {
                  show_orders: true
              }
          )


        else

          @success = false

        end

      else

        @success = false

      end

    end



  end

  def confirm

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      order = Order.find_by(id: params[:order_id])

      if order != nil

        if is_order_unconfirmed?(order)

          @success = true

          order.complete!

          increment_store_balance(order)

          order.update!(
              admins_reviewing: [],
              confirmed_by: current_admin.full_name
          )


          ActionCable.server.broadcast 'unconfirmed_orders_channel', {
              order_confirmed: true,
              order_id: order.id
          }

          ActionCable.server.broadcast "view_unconfirmed_order_channel_#{order.id}", {
              order_confirmed: true
          }


          send_store_orders(order)

          send_customer_orders(order)

          notify_unavailable_products(order)


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

      order = Order.find_by(id: params[:order_id])

      if order != nil

        if is_order_unconfirmed?(order)

          @success = true

          store_user = order.store_user

          @store_name = store_user.store_name

          @store_user_id = store_user.id

          @store_owner = store_user.store_owner_full_name

          @store_owner_number = store_user.store_owner_work_number

          @store_number = store_user.store_number

          @store_has_sensitive_products = store_user.has_sensitive_products


          customer_user = order.customer_user

          @customer_name = customer_user.full_name

          @customer_user_id = customer_user.id

          @customer_number = customer_user.phone_number


          @country = order.get_country_name

          @delivery_time_limit = order.delivery_time_limit

          @ordered_at =  order.created_at

          @total_price = order.total_price.to_f.round(2)

          @total_price_currency = order.total_price_currency

          @receipt_url = order.receipt.url

          @products = []

          order.products.each do |ordered_product|

            ordered_product = eval(ordered_product)

            product = Product.find_by(id: ordered_product[:id])

            product_price = ordered_product[:price]

            product_currency = ordered_product[:currency]

            to_currency = 'USD'

            product_price = convert_amount(product_price, product_currency, to_currency).to_f.round(2)

            @products.push({
                               id: ordered_product[:id],
                               quantity: ordered_product[:quantity],
                               price: product_price,
                               currency: to_currency,
                               product_options: ordered_product[:product_options],
                               name: product.name,
                               picture: product.main_picture.url
                           })

          end


          @delivery_location = order.delivery_location




        else

          @success = false

        end


      else

        @success = false

      end

    end



  end

  def search_unconfirmed_orders

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      # search for unconfirmed orders by store name or customer name

      # filter orders by country and time exceed

      @unconfirmed_orders = []

      search = params[:search]

      country = params[:country]

      time_exceeded = params[:time_exceeded]


      if search != nil

        search = search.strip

        unconfirmed_orders = get_unconfirmed_orders

        unconfirmed_orders = unconfirmed_orders.where("store_name ILIKE ?", "%#{search}%").or( unconfirmed_orders.where("customer_name ILIKE ?", "%#{search}%") )

        if !country.blank?

          unconfirmed_orders = unconfirmed_orders.where(country: country)

        end

        if !time_exceeded.blank? && is_positive_integer?(time_exceeded)

          time_exceeded = time_exceeded.to_i

          unconfirmed_orders = unconfirmed_orders.where('delivery_time_limit <= ?', time_exceeded.minutes.ago)

        end


        unconfirmed_orders.each do |order|

          @unconfirmed_orders.push( get_unconfirmed_orders_item(order) )

        end

      end

    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      @unconfirmed_orders = []

      unconfirmed_orders = get_unconfirmed_orders

      unconfirmed_orders.each do |order|

        @unconfirmed_orders.push( get_unconfirmed_orders_item(order) )

      end


      @countries = get_countries

      @time_exceeded_filters = {
          30 => 'More than 30 minutes',
          60 => 'More than 1 hour',
          180 => 'More than 3 hours',
          360 => 'More than 6 hours',
          540 => 'More than 9 hours',
          720 => 'More than 12 hours',
          900 => 'More than 15 hours',
          1440 => 'More than 1 day',
          4320 => 'More than 3 days',
          10080 => 'More than 7 days',
          14400 => 'More than 10 days',
          20160 => 'More than 14 days',
          28800 => 'More than 20 days',
          43200 => 'More than 30 days',
          64800 => 'More than 45 days',
          86400 => 'More than 60 days'
      }


    end

  end

  private



  def get_unconfirmed_orders_item(order)

    {
        id: order.id,
        store_name: order.get_store_name,
        customer_name: order.get_customer_name,
        country: order.get_country_name,
        ordered_at: order.created_at,
        delivery_time_limit: order.delivery_time_limit,
        store_has_sensitive_products: order.store_has_sensitive_products
    }


  end

  def get_unconfirmed_orders

    Order.all.where(status: 2, store_handles_delivery: true, store_confirmation_status: 2).where('delivery_time_limit <= ?', DateTime.now.utc)

  end


end
