class UnsuccessfulOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include OrderHelper

  include ProductsHelper

  before_action :authenticate_admin!


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
              unsuccessful_orders: driver.get_unsuccessful_orders
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
