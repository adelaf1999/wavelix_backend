class UnsuccessfulOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper


  before_action :authenticate_admin!


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
