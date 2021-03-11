class OrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include ValidationsHelper

  include OrderHelper

  before_action :authenticate_admin!


  def show

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      order = Order.find_by(id: params[:order_id])

      if order != nil

        @success = true

        @products = get_order_products(order)


        driver = Driver.find_by(id: order.driver_id)


        if driver != nil

          @driver_id = driver.id

          @driver_name = driver.name

        end


        @status = order.status

        @delivery_location = order.delivery_location

        @ordered_at = order.created_at


        @store_user_id = order.store_user_id

        @store_name = order.get_store_name


        @customer_user_id = order.customer_user_id

        @customer_name = order.get_customer_name


        @country = order.get_country_name


        if order.delivery_fee != nil

          @delivery_fee = order.delivery_fee.to_f.round(2)

          @delivery_fee_currency = order.delivery_fee_currency

        end


        if order.order_type != nil

          @order_type = order.order_type

        end


        @store_confirmation_status = order.store_confirmation_status

        @store_handles_delivery = order.store_handles_delivery

        @customer_canceled_order = order.customer_canceled_order


        if !order.order_canceled_reason.blank?

          @order_canceled_reason = order.order_canceled_reason

        end


        if order.store_fulfilled_order != nil

          @store_fulfilled_order = order.store_fulfilled_order

        end


        if order.driver_fulfilled_order != nil

          @driver_fulfilled_order = order.driver_fulfilled_order

        end


        @total_price = order.total_price.to_f.round(2)

        @total_price_currency = order.total_price_currency


        if order.delivery_time_limit != nil

          @delivery_time_limit = order.delivery_time_limit

        end



        if order.store_arrival_time_limit != nil

          @store_arrival_time_limit = order.store_arrival_time_limit

        end


        if order.receipt.url != nil

          @receipt_url = order.receipt.url

        end


        if !order.confirmed_by.blank?

          @confirmed_by = order.confirmed_by

        end


        if !order.canceled_by.blank?

          @canceled_by = order.canceled_by

        end


        if order.resolve_time_limit != nil

          @resolve_time_limit = order.resolve_time_limit

        end


        @store_payments = []


        order.payments.where.not(store_user_id: nil).each do |payment|

          @store_payments.push( get_payment_item(payment))

        end



        @driver_payments = []


        order.payments.where.not(driver_id: nil).each do |payment|

          @driver_payments.push(get_payment_item(payment))

        end


      else

        @success = false

      end

    end


  end


  def search

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      # search for orders by store name and customer name

      # filter orders by status, country, store handles delivery

      @orders = []


      store_name = params[:store_name]

      customer_name = params[:customer_name]

      limit = params[:limit]

      status = params[:status]

      country = params[:country]

      store_handles_delivery = params[:store_handles_delivery]


      if store_name != nil && customer_name != nil && is_positive_integer?(limit)

        store_name = store_name.strip

        customer_name = customer_name.strip

        orders = Order.all.where("store_name ILIKE ?", "%#{store_name}%").where("customer_name ILIKE ?", "%#{customer_name}%").limit(limit)


        if is_status_valid?(status)

          status  = status.to_i

          orders  = orders.where(status: status)

        end


        if !country.blank?

          orders = orders.where(country: country)

        end


        if !store_handles_delivery.blank?

          store_handles_delivery = eval(store_handles_delivery)

          if is_boolean?(store_handles_delivery)

            orders = orders.where(store_handles_delivery: store_handles_delivery)

          end


        end


        orders = orders.order(created_at: :desc)


        orders.each do |order|

          order_data = {
              id: order.id,
              store_name: order.get_store_name,
              customer_name: order.get_customer_name,
              status: order.status,
              country: order.get_country_name,
              store_handles_delivery: order.store_handles_delivery,
              ordered_at: order.created_at
          }

          driver = Driver.find_by(id: order.driver_id)

          order_data[:driver_name] = driver.nil? ? 'N/A' : driver.name

          @orders.push(order_data)

        end


      end


    end

  end


  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      @orders = []

      limit = params[:limit]


      if is_positive_integer?(limit)

        orders = Order.all.order(created_at: :desc).limit(limit)

        orders.each do |order|

          order_data = {
              id: order.id,
              store_name: order.get_store_name,
              customer_name: order.get_customer_name,
              status: order.status,
              country: order.get_country_name,
              store_handles_delivery: order.store_handles_delivery,
              ordered_at: order.created_at
          }

          driver = Driver.find_by(id: order.driver_id)

          order_data[:driver_name] = driver.nil? ? 'N/A' : driver.name

          @orders.push(order_data)

        end

      end


      @status_options = Order.statuses

      @countries = get_countries


    end

  end


  private


  def get_payment_item(payment)

    amount = payment.amount

    fee = payment.fee


    from_currency = payment.currency

    to_currency = 'USD'


    amount = convert_amount(amount, from_currency, to_currency).to_f.round(2)

    fee = convert_amount(fee, from_currency, to_currency).to_f.round(2)

    net = (amount - fee).round(2)


    {
        id: payment.id,
        amount: amount,
        fee: fee,
        net: net,
        currency: to_currency
    }

  end


  def get_order_products(order)

    products = []


    order.products.each do |ordered_product|

      ordered_product = eval(ordered_product)

      product = Product.find_by(id: ordered_product[:id])

      product_price = ordered_product[:price]

      product_currency = ordered_product[:currency]

      to_currency = 'USD'

      product_price = convert_amount(product_price, product_currency, to_currency).to_f.round(2)

      products.push({
                        id: ordered_product[:id],
                        quantity: ordered_product[:quantity],
                        price: product_price,
                        currency: to_currency,
                        product_options: ordered_product[:product_options],
                        name: product.name,
                        picture: product.main_picture.url
                    })

    end


    products

  end

  def is_boolean?(arg)

    [false, true].include?(arg)

  end

  def is_status_valid?(status)

    if !status.blank?

      status = status.to_i

      Order.statuses.values.include?(status)


    else

      false

    end

  end


end
